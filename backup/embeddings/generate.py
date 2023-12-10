import os
import torch

from langchain.embeddings import LocalAIEmbeddings
from langchain.document_loaders import TextLoader
from langchain.llms import HuggingFacePipeline
from langchain.text_splitter import RecursiveCharacterTextSplitter

from transformers import AutoTokenizer, TextStreamer, GenerationConfig, BitsAndBytesConfig,pipeline,AutoModelForCausalLM
from langchain.document_loaders import DirectoryLoader

import pickle
import faiss
from langchain.vectorstores import Chroma

import numpy as np
import pickle

from langchain.embeddings import HuggingFaceEmbeddings
# Source and destination directories
source_dir = "source"
dest_dir = "bin"


model_name = "mistralai/Mistral-7B-Instruct-v0.1"
hub_name = "StarkWizard/Mistral-7b-instruct-cairo-instruct"




model_kwargs = {

    "device": "cpu"
}

embeddings = HuggingFaceEmbeddings(model_name=hub_name, model_kwargs=model_kwargs)


for subdir in os.listdir(source_dir):
    print("subdir:",subdir)
    subdir_path = os.path.join(source_dir, subdir)
    loader = DirectoryLoader(subdir_path, glob="./*.txt", loader_cls=TextLoader)
    documents = loader.load()
    print("splitting")
    text_splitter = RecursiveCharacterTextSplitter(
                                               chunk_size=1000, 
                                               chunk_overlap=200)

    texts = text_splitter.split_documents(documents)
    print(texts[0])
    print("creating store")
    vectorStore = Chroma.from_documents(texts, embeddings, collection_name=subdir,persist_directory=source_dir+"/"+subdir)

