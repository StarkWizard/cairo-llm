# Contribution Guide for StarkWizard

## Prerequisites

Before contributing to StarkWizard, please note the following requirements:

- **GPU Requirements for Training Models**: A GPU with at least 8 GB of VRAM is needed for training models.
- **CPU and Memory for Merging**: Merging is performed on the CPU and requires approximately 8 GB of RAM.
- **Python and Conda Installation**: It is highly recommended to install Python and Conda. 
- **Virtual Environment**: Creating a virtual environment (venv) is advisable due to the extensive and specific requirements of the project, including fixed versions of some libraries.

## How to Contribute

### If You Are Not Familiar with Machine Learning

You can still contribute by helping to expand the corpus of question and answer data used to train the model. The `sources.txt` document shows a variety of sources used, and some topics are not fully covered, leading to inaccuracies in the model generation.

- **Working on Topics**: Go to the `corpus_src/train` directory to see the list of covered topics. Each CSV file represents a source and a topic. For example, `alexandria_queue.csv` contains training data on the topic of queues from the Alexandria project.
- **Contributing to a Topic**: You can open any CSV file to see the existing data and decide if you can or want to contribute to the topic. You can use a new source or add to the existing sources.
- **Using a New Source**: If you add data from a new source 'X', create a file named `X_my_topic.csv` and add 'X' to the `sources.txt` file.
- **Submitting Your Contribution**: Push your file and create a Pull Request (PR). If it passes the tests, it will be integrated into the project and added to the model during the next training session.
- 

### If You Wish to Participate in Training

- **Uploading Models**: Direct the uploads of the models you generate to your Hugging Face account to avoid overwriting the reference model. After testing, we may switch the model to our StarkWizard account.
- **Tasks Available**: Optimize hyperparameters and parameters, such as learning rate, optimizer, or the Q and dropout of the implemented QLora.
  
  

### If You Wish to Participate in Quantization

- **Supported Formats**: Two formats are currently supported - AWQ and GGUF. GGUF is the only format supported on Apple Silicon and by LM Studio.
- **Notebooks**: Two notebooks are available, each corresponding to one of the formats. Note that not all cells need to be run every time; some are for installing or compiling libraries.
- **Improvements**: Generate variations of models with different parameters, such as multiple Q values. 
- **Testing and Uploading**: Similar to model training, test your models and upload them to your Hugging Face account. We will import them after testing.

---

Your contributions are vital to the growth and improvement of the StarkWizard project. We look forward to your valuable input and collaboration!
