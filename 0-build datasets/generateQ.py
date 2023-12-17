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

chat_history=[]
chat=None

def remove_gemini_format_errors(text):
    # remove the indice of the line
    pattern = r'^\d+\.\s|^"\d+\."'
    okc = re.sub(pattern, '', text, flags=re.MULTILINE)
    text = okc.replace('\n\n', '\n') # sometimes I get /n/n
    text = okc.replace('\n\n', '\n') # sometimes I get /n/n/n/n
    return text

def remove_duplicates(text):
    lines = text.split("\n")
    unique_lines = []
    
    for line in lines:
        if line not in unique_lines:
            unique_lines.append(line)
    
    formatted_text = "\n".join(unique_lines)
    return formatted_text

def remove_important_errors(text):
    text = remove_duplicates(text)
    okc = text.replace('", "', '","')
    return okc

def count_lines(text):
    return text.count('","')

def error_generating(answer):
    console.print(nok_prefix + "[bold red]Error in the returned answer: [/bold red]")
    console.print(answer)
    exit(1)


#'''I need you to write list as csv of {nbQ} different standalone questions and answers about a text, 
#  IMPORTANT: the text should be in the exact format "question","answer" csv format,no line number. a reader that does not have the text should understand.
#                                   ,do short answers, Here is the text: '''
#
def generateQ(text,nbQ):   
    console.print(ok_prefix + "[bold green]Generating... [/bold green]")
    with progress:
        task = progress.add_task("[cyan]Generating questions..", total=nbQ)

        response = chat.send_message(f'''Generate a list of {nbQ} questions and answers in CSV format. 
                                     Each question must be followed by an answer and surrounded by quotation marks like "question","answer". 
                                     Do never put line index.
                                     IMPORTANT: all answers should end with an "
                                     make sure a reader can understand them without the original text.
                                     answer concisely, limiting the answer to 3 sentences maximum
                                     Here is the text''' + text)
        

        answer = remove_important_errors(response.text)
        count = count_lines(answer)
        if count in (0,1) :
            error_generating(answer)
        progress.update(task, completed=count)
        progress.refresh()

        #print(answer)

        while(count<nbQ):
            if answer.endswith('"'):
                answer+='\n'
            response = chat.send_message("continue")
            text=remove_important_errors(response.text)
            ncount = count_lines(text)
            if ncount in (0,1) :
                error_generating(text)
            count +=ncount
            if not answer.endswith("\n"):
                if text.startswith("\""):
                    answer+="\"\n"
            answer+=text
            progress.update(task, completed=count)
            progress.refresh()
            
    return remove_gemini_format_errors(answer)
   
def convert_to_csv(input_file,nbQ):
    # Check if csv file already exists
    base_name, _ = os.path.splitext(input_file)
    csv_file = base_name + '.csv'

    with open(input_file, 'r') as input_f:
        data= input_f.read()
    data_to_append = generateQ(data,nbQ)

    # check th CSV files qre valid
    try:
        csv_buffer = StringIO(data_to_append)
        df = pd.read_csv(csv_buffer)
        
        duplicates = df.duplicated()
        df = df.drop_duplicates()
        num_duplicates = duplicates.sum()
    except Exception as e:
        console.print(nok_prefix+"[bold red]malformed csv, saving in another file[/bold red]")
        console.print(nok_prefix+"malformed csv, saving in another file")
        # save into debug
        with open("debug_"+csv_file, 'w') as csv_f:
            csv_f.write(data_to_append)
            exit(1)
            
    console.print(ok_prefix+"[bold green]Perfctly formatted CSV[/bold green]")
    console.print(f"Number of duplicated lines {num_duplicates}")
    
    if os.path.exists(csv_file) and os.path.getsize(csv_file) > 2:
        # if there is a csv file already, append file to the end
        df1 = pd.read_csv(csv_file)
        df_combined = pd.concat([df1, df], ignore_index=True)
        df_combined.to_csv(csv_file, quoting=csv.QUOTE_ALL,index=False)
    else:
        with open(csv_file, "w", newline='') as file:
            file.write("question,answer\n")
        df.to_csv(csv_file,quoting=csv.QUOTE_ALL, index=False, header=False)

    return data_to_append

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convertit un fichier texte en fichier CSV ou ajoute le contenu à un fichier CSV existant.")
    parser.add_argument("input", help="source filename")
    parser.add_argument("--nbQ", type=int, default=30, help="Number of questions answers.")
   
    
    args = parser.parse_args()

    GOOGLE_API_KEY=os.getenv('GEMINI_KEY')
    if(GOOGLE_API_KEY==None) :
        console.print(nok_prefix + "Google API Key Not Defined")
        exit()
    else:
        console.print(ok_prefix + "Google API Key Defined")
    
    genai.configure(api_key=GOOGLE_API_KEY)
    console.print(ok_prefix + "Google API [bold green]Connected[/bold green]")
    try:
        model = genai.GenerativeModel('gemini-pro')
        chat = model.start_chat(history=[])
        csv = convert_to_csv(args.input,args.nbQ)

        
    except Exception as e:
        console.print(nok_prefix + "Following error: "+"[bold red]"+str(e)+"[/bold red]")
