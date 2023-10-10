## cairo-llm
a set of notebooks for training llms on cairo

**corpus_src**
Contains the training and test corpus for fine-tuning on cairo language
You need to regenerate the dataset after modifying the csv files, and before fine tuning again.

**dataset-code-llama-instruct** 
use this notebook to generate the dataset formatted for code llama instruct.

**train-code-llama-instruct** 
Notebook to fine tune and quantize + upload to hugging face