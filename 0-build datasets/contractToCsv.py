import importlib

from QA.cairoParser import CairoParser
import argparse
import os
import glob
from rich.console import Console
import QA.cairoParser
importlib.reload(QA.cairoParser)

from QA.QAGenerator import qaGenerator
import QA.QAGenerator
importlib.reload(QA.QAGenerator)

overwrite = False

def generateQA(parser):
    
    qa = qaGenerator(parser)

    return qa.getQA()


def process_file(file_path, verbose):
    with open(file_path, 'r') as file:
        code = file.read()
    parser = CairoParser(code)
    
    if verbose:
        parser.display_ast()
    
    return generateQA(parser)

ok_prefix = "[bold green]->[/bold green]"
nok_prefix = "[bold red]->[/bold red]"



def main():
    console = Console()
    parser = argparse.ArgumentParser(description="codeGen CLI Tool")
    parser.add_argument("directory", help="Directory containing .cairo files")
    parser.add_argument("-v", "--verbose", help="Increase output verbosity", action="store_true")
    parser.add_argument("-o", "--overwrite", action="store_true", help="Overwrite existing files")

    args = parser.parse_args()

    overwrite = args.overwrite
    
    verbose = True if args.verbose else False

    # Parcourir récursivement les fichiers .cairo dans le répertoire spécifié et ses sous-répertoires
    for root, _, files in os.walk(args.directory):
        for file_name in files:
            if file_name.endswith(".cairoc"):
                file_path = os.path.join(root, file_name)
                console.print(ok_prefix + "[bold yellow]Parsing[/bold yellow] contract: "+ "[bold yellow]"+ file_path+ "[/bold yellow]")
                csv_file_path = os.path.splitext(file_path)[0] + ".csv"
                if os.path.isfile(csv_file_path) and overwrite==False:
                    console.print(nok_prefix + f"[bold green]Processed [/bold green]{file_path} -> [bold red]csv already created, use -o to overwrite[/bold red]")
                else:
                    parsed_code = process_file(file_path, verbose)
                    if(parsed_code is None):
                        console.print(nok_prefix + f"[bold green]Processed [/bold green]{file_path} -> [bold red]skipped, nothing useful in the file[/bold red]")
                    else:
                                        
                        with open(csv_file_path, 'w') as csv_file:
                            csv_file.write(parsed_code)
                        console.print(ok_prefix + f"[bold green]Processed [/bold green]{file_path} -> [bold blue]{csv_file_path}[/bold blue]")

if __name__ == "__main__":
    main()