import importlib
from cairoParser import CairoParser,Node
import argparse
import os
import glob
from rich.console import Console
import cairoParser
importlib.reload(cairoParser)

def process_file(file_path, verbose):
    with open(file_path, 'r') as file:
        code = file.read()
    parser = CairoParser(code)
    
    if verbose:
        parser.display_ast()
        
    return parser.generate_code()

ok_prefix = "[bold green]->[/bold green]"
nok_prefix = "[bold red]->[/bold red]"

def main():
    console = Console()
    parser = argparse.ArgumentParser(description="codeGen CLI Tool")
    parser.add_argument("directory", help="Directory containing .cairo files")
    parser.add_argument("-v", "--verbose", help="Increase output verbosity", action="store_true")
    args = parser.parse_args()
    
    verbose = True if args.verbose else False

    # Parcourir les fichiers .cairo dans le répertoire spécifié
    for file_path in glob.glob(os.path.join(args.directory, "*.cairo")):
        parsed_code = process_file(file_path, verbose)
        csv_file_path = os.path.splitext(file_path)[0] + ".csv"
        console.print(ok_prefix + "[bold yellow]Parsing[/bold yellow] contract: "+ "[bold yellow]"+ file_path+ "[/bold yellow]")
        with open(csv_file_path, 'w') as csv_file:
            csv_file.write(parsed_code)
        console.print(ok_prefix + f"[bold green]Processed [/bold green]{file_path} -> [bold blue]{csv_file_path}[/bold blue]")



if __name__ == "__main__":
    main()