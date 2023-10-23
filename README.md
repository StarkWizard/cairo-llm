# StarkWizard 🪄

![StarkWizard Logo](path_to_logo/StarkWizard_logo.png)

**StarkWizard** is a state-of-the-art Language Model (LLM) tailored for the Cairo smart contract language of StarkNet. With our meticulously designed training process and dedicated integration with StarkNet's intricacies, we aim to provide a robust and reliable LLM for all your Cairo smart contract needs.

## Table of Contents
- [StarkWizard 🪄](#starkwizard-)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Directory Structure](#directory-structure)
  - [Contribution Guidelines](#contribution-guidelines)
  - [Support \& Feedback](#support--feedback)
  - [License](#license)

## Features
- **Cairo LLM Integration**: Crafted specifically for Cairo's smart contract language.
- **Training Notebooks**: Easy-to-follow notebooks to train different models.
- **Merge Capabilities**: Seamlessly merge the training weights of PEFT with the original model.
- **Inference with Hugging Face**: Utilize models pushed to Hugging Face for swift inference tasks.

## Installation
Create a venv and install the requirements
```conda create -n cairo-llm python=x.x anaconda <-- replace x.x by your python version 9.x minimum
pip install -r requirements.txt```

Activate the venv
```
conda activate cairo-llm
```

## Usage
To launch the endpoint, 

```
cd enpoint
python main.py
```

open a browser and navigate to the address given in the console

## Directory Structure
```
StarkWizard/
│
├── Train/ # Contains notebooks for training models.
│
├── corpus_src/ # Contains csv files for constructing training and evaluation corpus.
│
├── merge/ # Notebooks for merging training weights with original model and pushing to Hugging Face.
│
├── Infere/ # Notebooks for inference, utilizing models on Hugging Face.
│
├── datasets/ # Notebooks for generating the dataset and push to Hugging Face
│
├── endpoint/ # A generation endpoint, with a basic UI
│
└── ... # Other directories and files.
```

## Contribution Guidelines
StarkWizard is an open-source project, and we welcome contributions of all kinds: new models, bug fixes, improvements to the documentation, and more. See our [contributing guide](CONTRIBUTING.md) for more details on how to get started.

## Support & Feedback
For support, questions, or feedback, please open an issue or mail wizard@starkwizard.com.

## License
StarkWizard is open-sourced under the [MIT License](LICENSE). See the LICENSE file for more details.

---
