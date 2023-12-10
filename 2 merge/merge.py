import torch
import wizardlib as wizard
from rich.console import Console
import argparse
console = Console()

wizard.disableWarnings()

ok_prefix = "[bold green]->[/bold green]"
nok_prefix = "[bold red]->[/bold red]"

platform = wizard.getPlatform()
hasGPU = wizard.hasGPU(platform)

#if platform=="mac":
#    console.print("[bold red]Not supported on MacOS[/bold red]")
 #   exit(1)

#--------------------------
# Before doing anything
# log into HF Hub
#--------------------------
from huggingface_hub import login
login()


# models
defaul_model_name = "codellama/CodeLlama-7b-Instruct-hf"
defaul_peft_model = "StarkWizard/llama-2-7b-cairo-trained-PEFT"
default_hub_name = "StarkWizard/codellama-cairo-instruct"

console.print(f"Platform Detected: [bold green]{platform}[/bold green]")

import os
os.environ["TOKENIZERS_PARALLELISM"] = "false"

parser = argparse.ArgumentParser(description="Training Arguments.")
parser.add_argument("--model_name", type=str, default=defaul_model_name, help="Name of the model to train")
parser.add_argument("--peft_model", type=str, default=defaul_peft_model, help="Name of the PEFT model")
parser.add_argument("--hub_name", type=str, default=default_hub_name, help="upload model to hub name")

model_name = parser.parse_args().model_name
peft_model = parser.parse_args().peft_model
hub_name = parser.parse_args().hub_name

from transformers import AutoModelForCausalLM
from peft import PeftModel
import torch
from transformers import  AutoTokenizer, BitsAndBytesConfig

console.print(ok_prefix + "[green]1/5 - Initializing Tokenizer[/green]")
tokenizer = AutoTokenizer.from_pretrained(model_name, use_fast=True)
tokenizer.pad_token = tokenizer.eos_token

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype="float16",
    bnb_4bit_use_double_quant=True,
)

console.print(ok_prefix + "[green]2/5 - Initializing Original Model[/green]")
model = AutoModelForCausalLM.from_pretrained(pretrained_model_name_or_path=model_name,
                                             trust_remote_code=True,
                                             low_cpu_mem_usage=True,
                                             device_map={"": "cpu"},
                                             torch_dtype=torch.float16
                                             )

console.print(ok_prefix + "[green]3/5 - Initializing Peft Model[/green]")
model_to_merge  = PeftModel.from_pretrained(model, peft_model,
                        torch_dtype=torch.bfloat16, 
                        device_map={"": "cpu"}
                         )

console.print(ok_prefix + "[green]4/5 - Merging[/green]")
merged_model = model_to_merge.merge_and_unload()
#model.save_pretrained("cairo-mistral")

console.print(ok_prefix + "[bold green]5/5 - Uploading to HF Hub[/bold green]")
merged_model.push_to_hub(hub_name,max_shard_size="1GB")
console.print(ok_prefix + "[bold green]Done[/bold green]")