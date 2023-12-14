
# Merge Command Help

## Description
This command is used for merging models. It accepts various arguments to customize the merging process.

## Usage
```bash
merge [options]
```

## Arguments

### Optional Arguments
- `--model_name` (str): Name of the model to train. Default is `defaul_model_name`.
- `--peft_model` (str): Name of the PEFT model. Default is `defaul_peft_model`.
- `--hub_name` (str): Upload model to the specified hub name. Default is `default_hub_name`.

## Examples
```bash
merge --model_name="my_model" --peft_model="peft_example" --hub_name="my_merged"
```

This example merges `my_model` with the PEFT model `peft_example` and uploads the result `my_merged` on HuggingFace.
