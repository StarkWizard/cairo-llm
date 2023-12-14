
# Train Command Help

## Description
This tool is used for training machine learning models. It accepts various arguments to customize the training process.

## Usage
```bash
train [options] modules
```

## Arguments

### Required Arguments
- `modules`: A list of target modules to train. This is a required argument and should be specified at the end of the command.

### Optional Arguments
- `--batch_size` (int): Batch size to train the model with. Default is `default_batch_size`.
- `--accumulation_steps` (int): Number of gradient accumulation steps. Default is `default_accumulation_steps`.
- `--epochs` (int): Number of epochs to train the model for. Default is `default_epochs`.
- `--model_name` (str): Name of the model to train. Default is `defaul_model_name`.
- `--model_file` (str): Name of the file for the model. Default is `None`.
- `--tokenizer_name` (str): Name of the tokenizer model. Default is `None`.
- `--dataset_name` (str): Name of the dataset used for training. Default is `defaul_dataset_name`.
- `--new_model` (str): Name of the newly trained model. Default is `defaul_new_model`.
- `--wandb_project` (str): Name of the WandB project. Default is `None`.
- `--lora_r` (int): LoRA r value. Default is `default_lora_r`.
- `--lora_alpha` (int): LoRA alpha value. Default is `default_lora_alpha`.
- `--lora_dropout` (float): LoRA dropout value. Default is `default_lora_dropout`.
- `--lr` (float): Learning rate for the model training. Default is `default_lr`.
- `--packing` (bool): Use Packing strategy in training. Default is `default_packing`.

## Examples
```bash
train --batch_size=32 --epochs=10 --model_name="my_model"
```

This example downloads from HuggingFace and trains `my_model` with a batch size of 32 for 10 epochs.
