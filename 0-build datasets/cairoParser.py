import re
import textwrap


indent_string="\t"

def formatStr(str,before="",after="",doStrip=True):
    if str is None: return ""
    if doStrip:
        str = str.strip()
    return before + str + after


def remove_first_line_with_brace(text):
    lines = text.split('\n')
    if lines and lines[0].strip() == '{':
        lines.pop(0)  # Supprime la première ligne
    res = '\n'.join(lines)

    return res

def change_indent(str, indent, popFirstLine=False):
    if str is None:
        return ""

    lines = str.splitlines()
    first_line = lines[0]+"\n" if popFirstLine  else ""
    rest_of_lines = lines[1:] if popFirstLine else lines

    original_string = textwrap.dedent('\n'.join(rest_of_lines))
    indented_string = ""

    for line in original_string.splitlines():
        indented_string += indent * "\t" + line + "\n"

    return first_line + indented_string

def getLineNb(text):
    lignes = text.splitlines()
    return len(lignes)


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
    
    def to_text(self,indent,traverse,mode="a"):
        src = indent_string*indent

        if(self.type=="fn"):
            
                src += formatStr(change_indent(self.comment,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.decoration,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.type,0), indent_string*indent, " ")
                src += formatStr(self.declaration,"","(")
                src += formatStr(self.parameters ,"", ") {")
                if mode=="a":
                    src+="\n"
                    src += formatStr(change_indent(self.content,indent+1),"", "\n" + indent_string*indent + "}\n",False)
        elif self.type=="use":           
                src += formatStr(change_indent(self.comment,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.decoration,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.type,indent), indent_string*indent, " ")
                src += formatStr(self.declaration," ")
                addendum=""
                if getLineNb(self.content)>1:
                    addendum="\n"+ indent_string*indent
                src += formatStr(change_indent(self.content,indent+1,True),"", addendum+"};\n",True)
        elif self.type=="struct":           
                src += formatStr(change_indent(self.comment,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.decoration,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.type,indent), indent_string*indent, " ")
                src += formatStr(self.declaration,""," ")
                if mode=="a":
                    addendum="\n"+ indent_string*indent
                    src += formatStr(change_indent(self.content,indent+1),"", addendum+"};",True)
                else:
                    src+="{"
        elif self.type=="trait":
                src += formatStr(change_indent(self.comment,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.decoration,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.type,indent), indent_string*indent, " ")
                src += formatStr(self.declaration,"")
                if mode=="a":
                    src += formatStr(change_indent(self.content,indent+1),"", "\n" + indent_string*indent + "}\n\n",False)
        elif self.type=="impl":            
                src += formatStr(change_indent(self.comment,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.decoration,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.type,indent), indent_string*indent, " ")
                src += formatStr(self.declaration,"")
                src += formatStr(self.parameters," of ","\n" )
                traverse = True
        elif self.type=="mod":            
                src += formatStr(change_indent(self.comment,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.decoration,indent), indent_string*indent, "\n")
                src += formatStr(change_indent(self.type,indent), indent_string*indent, " ")
                src += formatStr(self.declaration,"", " {")
                #src += formatStr(self.parameters," of ","\n" )
                traverse = True       
        if(traverse):
            for i in self.children:
                src += i.to_text(indent+1,traverse)
            if(self.type in ["impl","mod"]):
                src+="\n"+indent_string*indent+"}"
                
        return src
    
    
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
        self.fix_impl()

    def parse(self):
        token_pattern = r'#\[[^\]]*\]|(mod|impl|fn|use|trait|struct)\s+\w+|{|}|;|\//.*|/\*[\s\S]*?\*/|use\s+[\w:]+::\{[^}]*\}'
        tokens = list(re.finditer(token_pattern, self.code))

        for token in tokens:
            if token.group().startswith('#['):
                self.pending_decoration = (self.pending_decoration or '') + token.group()
            elif token.group().startswith('//') or token.group().startswith('/*'):
                if not self.brace_stack or self.brace_stack[-1].type != 'fn':
                    if(self.pending_comment is not None): self.pending_comment += '\n'
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

                if node_type == 'trait':
                    self.current_node.content = node_declaration  # Ajouter la déclaration du trait au contenu du nœud trait

        if self.brace_stack:
            raise SyntaxError("Unbalanced braces in the code.")


     
    def fix_fn(self, node=None,parent_type=None):
        if node is None:
            node = self.root
  
        # Parcourir récursivement tous les nœuds
        if(node.type!='trait'):
            for child in node.children:
                self.fix_fn(child,node.type)

        # Vérifier si le nœud est de type 'fn'
        if node.type == 'fn' and node.content:
            
            # Trouver l'index du premier bloc d'accolades '{'
            brace_index = node.content.find('{')
            if brace_index != -1:
                # Extraire la partie de la déclaration de la fonction
                fn_declaration = node.content[:brace_index]

                # Extraire les paramètres de cette partie
                match = re.match(r'\(([^)]*)\)', fn_declaration)
                if match:
                    node.parameters = match.group(1)

                    # Reconstruire le contenu du nœud en excluant uniquement la partie des paramètres extraite
                    node.content = fn_declaration[:match.start()] + node.content[brace_index:]
                    node.content = remove_first_line_with_brace(node.content)

    def fix_impl(self, node=None):
        if node is None:
            node = self.root

        # Parcourir récursivement tous les nœuds
        for child in node.children:
            self.fix_impl(child)

        # Vérifier si le nœud est de type 'impl'
        if node.type == 'impl' and node.content:
            # Trouver l'index de la première occurence de 'of'
            of_index = node.content.find('of')
            if of_index != -1:
                # Extraire la partie après 'of' jusqu'à '{' inclus
                impl_parameters = node.content[of_index + 2 : node.content.find('{') + 1]
                # Assigner la partie extraite à node.parameters
                node.parameters = impl_parameters
                print(impl_parameters)
                # Supprimer la partie extraite de node.content
                node.content = node.content.replace(impl_parameters, '', 1).strip()


    def find_nodes(self,node_type):
        node_list = []  # Une liste pour stocker les noms des fonctions trouvées

        def traverse(node):
            if node.type == node_type:
                node_list.append(node)

            # Parcourir récursivement les enfants du nœud
            if(node.type!='trait'):
                for child in node.children:
                    traverse(child)

        # Commencez la recherche à partir de la racine de l'arbre syntaxique
        traverse(self.root)

        return node_list
    
    def to_text(self,node_list,indent,traverse):
        src=""
        for i in node_list:
            src += i.to_text(indent,traverse,"a")
        return src
    
    def display_ast(self, node=None, level=0):
        if node is None:
            node = self.root
        print("  " * level + str(node))
        for child in node.children:
            self.display_ast(child, level + 1)
            
    #for debug purpose only to see what the AST got
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
    