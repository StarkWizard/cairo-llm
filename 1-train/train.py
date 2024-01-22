
import torch
import wizardlib as wizard
from rich.console import Console
import argparse
console = Console()

# Remove Annoying Warnings
import warnings
warnings.filterwarnings("ignore", category=UserWarning, module="transformers.utils.generic")
warnings.filterwarnings("ignore", category=UserWarning, module="trl.trainer.ppo_config")
warnings.filterwarnings("ignore", message="torch.utils.checkpoint: please pass in use_reentrant=True or use_reentrant=False explicitly")

ok_prefix = "[bold green]->[/bold green]"
nok_prefix = "[bold red]->[/bold red]"

platform = wizard.getPlatform()
hasGPU = wizard.hasGPU(platform)

#--------------------------
# Test GPU availability
#--------------------------
if not hasGPU:
    console.print(nok_prefix + "[bold red]GPU is not available. Please make sure your system has a compatible GPU.[/bold red]")
    console.print("You either need a PC with an NVdia GPU or a Mac with Apple M1/M2/M3 GPU.")
    exit(1)

gpuDevice = wizard.getDevice(platform)

console.print(f"Platform Detected: [bold green]{platform}[/bold green] with device [bold green]{gpuDevice}[/bold green]")

#--------------------------
# Before doing anything
# log into HF Hub
#--------------------------
from huggingface_hub import login
login()

# params & hyperparams
default_epochs = 3
default_lora_r = 64
default_lora_alpha=16
default_lora_dropout=0.1
default_batch_size = 2
default_accumulation_steps = 1
default_lr = 2e-4
default_packing = False
default_window = 512
# models
defaul_model_name = "codellama/CodeLlama-7b-Instruct-hf"
default_tokenizer_name = "codellama/CodeLlama-7b-Instruct-hf"
defaul_dataset_name = "StarkWizard/cairo-instruct"
defaul_new_model = "StarkWizard/llama-2-7b-cairo-trained-PEFT"
default_max_seq_length = 1024

#target_modules=[
#        "q_proj",
#        "k_proj",
#        "v_proj",
#        "o_proj",
#        "up_proj",
#        "down_proj",
#        "gate_proj",
#        'lm_head',]

#--------------------------
# Parse args
#--------------------------
parser = argparse.ArgumentParser(description="Training Arguments.")
parser.add_argument("--batch_size", type=int, default=default_batch_size, help="Batch size to train the model with.")
parser.add_argument("--accumulation_steps", type=int, default=default_accumulation_steps, help="Gradient accumulation steps.")

parser.add_argument("--epochs", type=int, default=default_epochs, help="Number of epochs to train the model for.")
parser.add_argument("--model_name", type=str, default=defaul_model_name, help="Name of the model to train")
parser.add_argument("--model_file", type=str, default=None, help="Name of the file")

parser.add_argument("--tokenizer_name", type=str, default=None, help="Name of the model for the tokenizer")
parser.add_argument("--dataset_name", type=str, default=defaul_dataset_name, help="Name of the dataset")
parser.add_argument("--new_model", type=str, default=defaul_new_model, help="Name of the trained model")
parser.add_argument("--wandb_project", type=str, default=None, help="Name of the wandb project")
parser.add_argument("--lora_r", type=int, default=default_lora_r, help="lora r value")
parser.add_argument("--lora_alpha", type=int, default=default_lora_alpha, help="lora alpha value")
parser.add_argument("--lora_dropout", type=float, default=default_lora_dropout, help="lora dropout value")
parser.add_argument("--lr", type=float, default=default_lr, help="learning rate")
parser.add_argument("--packing",type=bool, default=default_packing, help="use Packing strategy")
parser.add_argument("--window",type=float, default=default_window, help="window size")
parser.add_argument("--max_seq_length",type=float, default=default_max_seq_length, help="max seuence length")
parser.add_argument("modules", nargs='+', help="target modules to train")

args = parser.parse_args()



target_modules = args.modules


# getting number of epochs
nb_epochs=3
if args.epochs > 0:
    nb_epochs = args.epochs

model_name = args.model_name
model_file = args.model_file
tokenizer_name = args.tokenizer_name
if(tokenizer_name is None):
    tokenizer_name = model_name

dataset_name = args.dataset_name
new_model = args.new_model
wandb_project = args.wandb_project
lora_dropout = args.lora_dropout
lora_alpha = args.lora_alpha
lora_r = args.lora_r
batch_size = args.batch_size
accumulation_steps = args.accumulation_steps
lr = args.lr
packing = args.packing
window = args.window
max_seq_length = default_max_seq_length

# Initializing WandB
if wandb_project is not None:
    import wandb

    wandb.init(
        # set the wandb project where this run will be logged
        project=wandb_project,
        # track hyperparameters and run metadata
        config={
        "epochs":nb_epochs,
        }
    )


#--------------------------
# Load model
#--------------------------


# Seems required, have seen issues in tokenization with parallelism
wizard.disableTokenizerParallelization()


import torch
from datasets import load_dataset, Dataset
from peft import LoraConfig ,prepare_model_for_kbit_training, get_peft_model
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments
from trl import SFTTrainer
import os

console.print(ok_prefix + "[green]Initializing Tokenizer[/green]")

# Load the tokenizer from the model (llama2)
tokenizer = AutoTokenizer.from_pretrained(tokenizer_name, add_eos_token=True, use_fast=False)
tokenizer.padding_side = "right"
tokenizer.pad_token_id = 18610

console.print(ok_prefix + "[green]Loading Dataset[/green]")

# load Dataset
from datasets import load_dataset

# Load the dataset
dataset_train = load_dataset(dataset_name, split="train", download_mode='force_redownload',verification_mode= "no_checks")
dataset_test = load_dataset(dataset_name, split="eval", download_mode='force_redownload',verification_mode="no_checks")
dataset_train = dataset_train.shuffle(seed=42)

console.print(ok_prefix + "[green]Loading Model[/green]")

additional_params = {'model_file': model_file} if model_file is not None else {}


if platform != "mac":
    from transformers import BitsAndBytesConfig
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16,
        bnb_4bit_use_double_quant=True,
    )
    model = AutoModelForCausalLM.from_pretrained(
        pretrained_model_name_or_path=model_name,
        quantization_config=bnb_config,
        low_cpu_mem_usage=True,
        **additional_params,
        device_map={"": 0}
    )
else:

    model = AutoModelForCausalLM.from_pretrained(
                pretrained_model_name_or_path=model_name,
                trust_remote_code=True,
                low_cpu_mem_usage=True,
                device_map=gpuDevice,
                 **additional_params,               
            )

model.resize_token_embeddings(len(tokenizer))
model.config.use_cache=False
model.config.pretraining_tp=1
model.config.window = 4096 
model.gradient_checkpointing_enable()
model = prepare_model_for_kbit_training(model)

peft_config = LoraConfig(
        r=lora_r, 
        lora_alpha=lora_alpha,
        lora_dropout=lora_dropout,
        bias="none",
        task_type="CAUSAL_LM", 
        target_modules=target_modules,
        inference_mode = False
    )

# a tester auto_find_batch_size=True


if wandb_project is not None:
    wand_to="wandb"
else:
    wand_to="none"
model = get_peft_model(model, peft_config)

additional_params = {'use_mps_device': True} if platform == "mac" else {} 

training_arguments = TrainingArguments(
    output_dir=new_model,
    per_device_train_batch_size=batch_size,
    gradient_accumulation_steps=accumulation_steps,
    gradient_checkpointing = True,
    evaluation_strategy="steps",
    learning_rate=lr,
    lr_scheduler_type="constant",
    warmup_ratio=0.03,
    max_grad_norm=0.3,
    save_strategy="epoch",
    logging_dir="./logs", 
    logging_steps=50,
    num_train_epochs=nb_epochs,
    group_by_length=True,
    fp16=False,
    report_to=wand_to,
    push_to_hub=True,
    adam_beta2=0.999,
    do_train=True,
    **additional_params
)

trainer = SFTTrainer(
    model=model,
    train_dataset=dataset_train,
    eval_dataset=dataset_test,
    peft_config=peft_config,
    dataset_text_field="text",
    args=training_arguments,
    tokenizer=tokenizer,
    packing=packing,
    max_seq_length=max_seq_length,
)
torch.cuda.empty_cache()
trainer.train()
trainer.model.push_to_hub(new_model)
tokenizer.push_to_hub(new_model)