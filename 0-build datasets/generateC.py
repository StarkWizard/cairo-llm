import argparse
import pathlib
import textwrap
import re
from rich.console import Console
from rich.progress import Progress
import google.generativeai as genai
import os
import pandas as pd
from io import StringIO
import csv

console = Console()
progress = Progress()
ok_prefix = "[bold green]->[/bold green]"
nok_prefix = "[bold red]->[/bold red]"

chat_history = []
chat = None



def remove_important_errors(text):
    okc = text.replace('", "', '","')
    return okc

def error_generating(answer):
    console.print(nok_prefix + "[bold red]Error in the returned answer: [/bold red]")
    console.print(answer)
    exit(1)

def is_text_valid(text):
    # Vérifie si le texte respecte les critères spécifiés
    double_quote_count = text.count('"')
    single_quote_count = text.count("'")
    curly_brace_count = text.count('{') - text.count('}')
    parentheses_count = text.count('(') - text.count(')')
    
    return (
        double_quote_count % 2 == 0
        and single_quote_count % 2 == 0
        and curly_brace_count == 0
        and parentheses_count == 0
    )



def generateC(text):

    generated_text = ""
    first_attempt = True
    max_count = 0
    print("genrating")
    response = chat.send_message(f'''Add decriptive Comments in english to the following smart contract
                            Do not comment lines that already have comments, do only add comment to 'fn','trait','struct','impl'
                            Important, place the comment above each block.For of each function comment before the declaration, not inside,describe the parameters and what the function does
                            For each 'trait' comment what the trait contains, on top of each 'struct' comment what the struct contains , on top of each 'impl' comment to what trait the impl is related.
                            Important do not add md decoration to the answer, just plain text /n''' + text)
    generated_text = remove_important_errors(response.text)

    while not is_text_valid(generated_text):
        console.print(nok_prefix + "Following error: " + "[bold red]" + "Incomplete generation, retrying" + "[/bold red]")
        response = chat.send_message("continue")
        answer = remove_important_errors(response.text)
        generated_text += answer
        max_count += 1
        if(max_count > 3):
            console.print(nok_prefix + "Following error: " + "[bold red]" + "Generation Failed !" + "[/bold red]")
            return ""
    return generated_text

def convert_to_cairoc(input_file, nb):
    base_name, _ = os.path.splitext(input_file)
    data_list = []

    for i in range(nb):
        csv_file = f"{base_name}_{i + 1}.cairoc"
        with open(input_file, 'r', encoding='utf-8') as input_f:
            data = input_f.read()
        data_to_append = generateC(data)

        if(data_to_append!="") :
            with open(csv_file, "w", encoding="utf-8") as file:
                file.write(data_to_append)
                

def process_directory(directory, nb):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".cairo"):
                file_path = os.path.join(root, file)
                convert_to_cairoc(file_path, nb)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Add comment to Cairo files and generate .cairoc files.")
    parser.add_argument("directory", help="Source directory containing .cairo files and subdirectories")
    parser.add_argument("-nb", "--num-iterations", type=int, default=1, help="Number of iterations to generate .cairoc files")
    
    args = parser.parse_args()

    GOOGLE_API_KEY = os.getenv('GEMINI_KEY')
    if GOOGLE_API_KEY is None:
        console.print(nok_prefix + "Google API Key Not Defined")
        exit()
    else:
        console.print(ok_prefix + "Google API Key Defined")

    genai.configure(api_key=GOOGLE_API_KEY)
    console.print(ok_prefix + "Google API [bold green]Connected[/bold green]")

    try:
        
        generation_config=genai.types.GenerationConfig(
            candidate_count=1,
            temperature=0.50)
        
        model = genai.GenerativeModel('gemini-pro',generation_config=generation_config)
        chat = model.start_chat( history=[] )
        
        if args.num_iterations < 1:
            console.print(nok_prefix + "Number of iterations must be at least 1")
            exit()
        
        process_directory(args.directory, args.num_iterations)

    except Exception as e:
        console.print(nok_prefix + "Following error: " + "[bold red]" + str(e) + "[/bold red]")
