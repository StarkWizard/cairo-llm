from langchain_community.llms import CTransformers
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.docstore.document import Document
from langchain.prompts import PromptTemplate
from langchain_community.embeddings import HuggingFaceBgeEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.chains.summarize import load_summarize_chain
from langchain.chains import RetrievalQA
from accelerate import Accelerator

import os 
import json
import time
import aiofiles
import csv
from rich.console import Console


model_name = "TheBloke/Amethyst-13B-Mistral-GGUF"

def load_llm():
    # Load the locally downloaded model here

    # Configuration du modèle
    config = {
        'max_new_tokens': 3000,
        'temperature': 0.01,
        'context_length': 7000,
        'gpu_layers': 0
    }
    
    # Initialisation du modèle avec indication explicite pour l'utilisation du GPU
    llm = CTransformers(
        model=model_name,
        model_type="mistral",
        max_new_tokens=1048,
        temperature=0.3,
        gpu_layers=0,
        config=config,
    )

    accelerator = Accelerator()
    llm, config = accelerator.prepare(llm, config)
    return llm



#load a text and create chunks of text
def file_processing(file_path):
    # Load data from text file
    with open(file_path, 'r') as file:
        data = file.read()

    question_gen = data

    splitter_ques_gen = RecursiveCharacterTextSplitter(
        chunk_size = 1000,
        chunk_overlap = 100
    )

    chunks_ques_gen = splitter_ques_gen.split_text(question_gen)

    document_ques_gen = [Document(page_content=t) for t in chunks_ques_gen]

    splitter_ans_gen = RecursiveCharacterTextSplitter(
        chunk_size = 300,
        chunk_overlap = 30
    )

    document_answer_gen = splitter_ans_gen.split_documents(
        document_ques_gen
    )

    return document_ques_gen, document_answer_gen

def clean_text(input_string):
    import re

    match = re.search("[A-Za-z]", input_string)
    if match:
        return input_string[match.start():]
    else:
        return input_string
    
#save generated files to "question,answer" csv file
def write_to_csv(file_path,ques_list,ans_list, force_overwritte=False):
    import os

    file_exists_and_not_empty = os.path.exists(file_path) and os.path.getsize(file_path) > 0
    mode = 'a' if file_exists_and_not_empty else 'w'

    if force_overwritte:
        mode = 'a'
        file_exists_and_not_empty=False
    
    with open(file_path, mode, encoding='utf-8') as file:
            if not file_exists_and_not_empty:
                file.write("question,answer\n")
            else :
                file.write("\n")
            for i, (q, a) in enumerate(zip(ques_list, ans_list)):
                # clean the text first
                question = clean_text(q)
                answer = clean_text(a)

                # formatting the output
                line = f'"{question}","{answer}"'

                # Do not add \n to the last line
                if i < len(ques_list) - 1:
                    line += '\n'
                file.write(line)



# Build The LLM Pipeline
def llm_pipeline(file_path):

    document_ques_gen, document_answer_gen = file_processing(file_path)



    llm_ques_gen_pipeline = load_llm()

    prompt_template = """
    You are an expert at creating questions based on documentation.
    Your goal is to prepare an LLM for training and build a dataset
    You do this by asking standalone questions about the text below.The question must be standalone, questions should not be repeated
    Here is the text:

    ------------
    {text}
    ------------

    Create questions that will help creating the dataset for LLM. 
    Make sure not to lose any important concepts.

    QUESTIONS:
    """

    PROMPT_QUESTIONS = PromptTemplate(template=prompt_template, input_variables=["text"])

    refine_template = ("""
    You are an expert at creating practice questions based on documentation.
    Your goal is to help preparing a dataset for training an LLM.
    We have received some practice questions to a certain extent: {existing_answer}.
    We have the option to refine the existing questions or add new ones.
    (only if necessary) with some more context below.
    ------------
    {text}
    ------------

    Given the new context, refine the original questions in English.
    If the context is not helpful, please provide the original questions.
    QUESTIONS:
    """
    )

    REFINE_PROMPT_QUESTIONS = PromptTemplate(
        input_variables=["existing_answer", "text"],
        template=refine_template,
    )

    ques_gen_chain = load_summarize_chain(llm = llm_ques_gen_pipeline, 
                                            chain_type = "refine", 
                                            verbose = True, 
                                            question_prompt=PROMPT_QUESTIONS, 
                                            refine_prompt=REFINE_PROMPT_QUESTIONS)

    ques = ques_gen_chain.run(document_ques_gen)

    embeddings = HuggingFaceBgeEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")

    vector_store = FAISS.from_documents(document_answer_gen, embeddings)

    llm_answer_gen = load_llm()

    ques_list = ques.split("\n")
    filtered_ques_list = [element for element in ques_list if element.endswith('?') or element.endswith('.')]

    answer_generation_chain = RetrievalQA.from_chain_type(llm=llm_answer_gen, 
                                                chain_type="stuff", 
                                                retriever=vector_store.as_retriever())

    return answer_generation_chain, filtered_ques_list


# from a text file, generate corresponding CSV file
def get_csv (file_path,target_dir):
    file_name = os.path.basename(file_path)
    answer_generation_chain, ques_list = llm_pipeline(file_path)
    ans_list = []
    base_folder = target_dir + "/"
    if not os.path.isdir(base_folder):
        os.mkdir(base_folder)
    output_file = base_folder+file_name+"_QA.csv"

    for question in ques_list:
        print("Question: ", question)
        answer = answer_generation_chain.run(question)
        print("Answer: ", answer)
        print("--------------------------------------------------\n\n")
        ans_list.append(answer)
    # Save answer to CSV file
        
    write_to_csv(output_file,ques_list,ans_list)

import argparse
def main():
    console = Console()
    parser = argparse.ArgumentParser(description="Generate QA CSV from text file")

    
    parser.add_argument("source_file", type=str, help="Name for the text file to be processed.")
    parser.add_argument("output_dir", type=str, help="Output directory")

    # Analyse des arguments fournis par l'utilisateur
    args = parser.parse_args()

   
    console.print(f"[bold green]Processing [/bold green]{args.source_file}...")
    get_csv(args.source_file,args.output_dir)
    console.print(f"[bold green]Saving to: [/bold green]{args.output_dir}...")


if __name__ == "__main__":
    main()