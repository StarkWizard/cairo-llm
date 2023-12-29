import re
import argparse
import os
import glob

class Node:
    def __init__(self, type_, declaration, parameters=None, content=None, comment=None, decoration=None, parent=None):
        self.type = type_
        self.declaration = declaration
        self.content = content
        self.comment = comment
        self.decoration = decoration
        self.parameters = parameters
        self.children = []
        self.parent = parent
        self.start_pos = 0

    def add_child(self, child):
        self.children.append(child)
        child.parent = self

    def __repr__(self):
        parts = [f"Node({self.type}"]

        if self.declaration:
            parts.append(f"decl='{self.declaration}'")
        if self.parameters:
            parts.append(f"params='{self.parameters}'")
        if self.type not in ["impl","mod"]:
            if self.content:
                content_preview = self.content.replace('\n', '\\n') if len(self.content) > 30 else self.content
                parts.append(f"content='{content_preview}'")
        if self.comment:
            comment_preview = self.comment[:30].replace('\n', '\\n') + '...' if len(self.comment) > 30 else self.comment
            parts.append(f"comment='{comment_preview}'")
        if self.decoration:
            decoration_preview = self.decoration[:30].replace('\n', '\\n') + '...' if len(self.decoration) > 30 else self.decoration
            parts.append(f"decoration='{decoration_preview}'")

        parts.append(f"{len(self.children)} children)")
        return ", ".join(parts)
    
class CairoParser:
    def __init__(self, code):
        self.code = code
        self.root = Node("root", "", "", None, None, None)
        self.current_node = self.root
        self.pending_comment = None
        self.pending_decoration = None
        self.brace_stack = [] 
        self.parse()
        self.fix_fn()

    def parse(self):
        token_pattern = r'#\[[^\]]*\]|(mod|impl|fn|use|trait|struct)\s+\w+|{|}|;|\//.*|/\*[\s\S]*?\*/|use\s+[\w:]+::\{[^}]*\}'
        tokens = list(re.finditer(token_pattern, self.code))

        for token in tokens:
            if token.group().startswith('#['):
                self.pending_decoration = (self.pending_decoration or '') + token.group()
            elif token.group().startswith('//') or token.group().startswith('/*'):
                if not self.brace_stack or self.brace_stack[-1].type != 'fn':
                    self.pending_comment = (self.pending_comment or '') + token.group()
            elif token.group() == '{':
                self.brace_stack.append(self.current_node)
            elif token.group() == '}':
                if self.brace_stack:
                    closing_node = self.brace_stack.pop()
                    closing_node.content = self.code[closing_node.start_pos:token.start()].strip()
                    self.current_node = closing_node.parent
                    if closing_node.type == 'fn':
                        self.pending_comment = None  # Annuler les commentaires à la sortie d'un bloc de fonction
            elif token.group().startswith(('mod ', 'impl ', 'fn ', 'use ', 'trait ', 'struct ')):
                node_type, node_declaration = token.group().split(maxsplit=1)
                new_node = Node(node_type, node_declaration, comment=self.pending_comment, decoration=self.pending_decoration, parent=self.current_node)
                new_node.start_pos = token.end()
                self.current_node.add_child(new_node)
                self.current_node = new_node
                self.pending_comment = None
                self.pending_decoration = None

        if self.brace_stack:
            raise SyntaxError("Unbalanced braces in the code.")


     
    def fix_fn(self, node=None):
        if node is None:
            node = self.root

        # Vérifier si le nœud est de type 'fn'
        if node.type == 'fn' and node.content:
            # Extraire les paramètres de 'content' et les déplacer vers 'parameters'
            match = re.match(r'\(([^)]*)\)', node.content)
            if match:
                node.parameters = match.group(1)
                # Supprimer les paramètres de 'content'
                node.content = re.sub(r'\([^)]*\)', '', node.content).strip()

        # Appliquer récursivement la fonction aux enfants du nœud
        for child in node.children:
            self.fix_fn(child)
                                        
    def display_ast(self, node=None, level=0):
        if node is None:
            node = self.root
        print("  " * level + str(node))
        for child in node.children:
            self.display_ast(child, level + 1)
            
    def generate_code(self, node=None, indent_level=-1):
        if node is None:
            node = self.root

        indent = '    ' * indent_level
        code = ""

        if node.decoration:
            code += indent + node.decoration + "\n"
        if node.comment:
            code += indent + node.comment + "\n"

        if node.type != 'root':
            # S'assurer que la déclaration n'est pas None avant de la concaténer
            declaration = node.declaration if node.declaration else ""
            code += indent + node.type + ' ' + declaration

            if node.type == 'fn':
                if node.parameters:
                    # Ajouter les paramètres pour les fonctions
                    code += '(' + node.parameters + ')'
                else:
                    code += '()'

            
            if node.type not in ["impl","mod"]:
                if node.content:
                    # Ajouter le contenu, en s'assurant qu'il n'est pas None
                    content = node.content.strip().replace('\n', '\n' + indent + '    ')
                    code += indent + '    ' + content + "\n"
            else:
                code += " {\n"

        # Générer le code pour les enfants du nœud
        for child in node.children:
            code += self.generate_code(child, indent_level + 1)

        if node !=self.root :
            code += indent + "}"
        code += "\n"

        return code
    
# Exemple d'utilisation
code = """
    use beer_barron::constants::{
        CONFIG::{
            pouet
        }
    };

use beer_barron::components::game::{
    Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig
};
use starknet::{ContractAddress, ClassHash};
use beer_barron::components::beer::{
    Brew, BrewBatchTrack, BeerID, get_beer_id_from_enum, get_recipe, BrewStatus
};

#[starknet::interface]
trait IBrewing<TContractState> {
    fn brew_beer(self: @TContractState, game_id: u64, beer_id: BeerID);
    fn bottle_beer(self: @TContractState, game_id: u64, batch_id: u64);
}

#[dojo::contract]
mod brewing {
 



    // TODO: move to a common place
    fn check_balance(world: IWorldDispatcher, game_id: u64, recipe_quantity: u64, hop_id: u64) {
        let mut hop_balance = get!(world, (game_id, get_caller_address(), hop_id), (ItemBalance));
        hop_balance.assert_balance(recipe_quantity.into());
        hop_balance.sub(recipe_quantity.into());
        set!(world, (hop_balance));
        if(toto) {
            if(ooo){
                lkjkmlj
            }
        }
    }
}

"""
def process_file(file_path):
    with open(file_path, 'r') as file:
        code = file.read()
    parser = CairoParser(code)
    parser.display_ast()
    return parser.generate_code()

def main():
    parser = argparse.ArgumentParser(description="Rust Parser CLI Tool")
    parser.add_argument("directory", help="Directory containing .cairo files")
    args = parser.parse_args()

    # Parcourir les fichiers .cairo dans le répertoire spécifié
    for file_path in glob.glob(os.path.join(args.directory, "*.cairo")):
        parsed_code = process_file(file_path)
        csv_file_path = os.path.splitext(file_path)[0] + ".csv"
        with open(csv_file_path, 'w') as csv_file:
            csv_file.write(parsed_code)
        print(f"Processed {file_path} -> {csv_file_path}")

if __name__ == "__main__":
    main()