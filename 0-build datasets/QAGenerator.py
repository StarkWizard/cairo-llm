import re

import importlib
from cairoParser import CairoParser,Node
import cairoParser
importlib.reload(cairoParser)

class qaGenerator:
    def __init__(self, parser):
        self.qa = "question,answer\n"
        self.parser = parser
    

    def addQA(self, question, answer):
        if question is None or answer is None:
            return
        if question == "" or answer == "":
            return
        self.qa += f'"{question}","{answer}"\n'

    
    # Collect all nodes defining a context relative to the root
    def buildContext(self,root, nodes,indent=0):
        context_nodes =  self.parser.find_nodes(root,nodes, False)
        context=""
        for n in context_nodes:
            context += self.parser.to_text(n, indent, True,"a")
        return context

    def addFnQuestions(self,node,indent,cntxt=""):
        # We first find all the context elements:
        cntxt_nodes =  self.buildContext(node,["use","struct","const","enum"],indent)
        if cntxt_nodes != "":
            cntxt_nodes += "\n"

        fn = self.parser.find_nodes(node,["fn"], False)
        
        for n in fn:
            question = cntxt + cntxt_nodes + self.parser.to_text(n, indent, False,"q")
            answer  = cntxt + cntxt_nodes +self.parser.to_text(n, indent, False,"a")
            self.addQA(question,answer)

    def addImplQuestions(self,node,indent,cntxt=""):
                # We first find all the context elements:
        cntxt_nodes =  self.buildContext(node,["use","struct","const","enum","trait"],indent)
        if cntxt_nodes != "":
            cntxt_nodes += "\n"

        fn = self.parser.find_nodes(node,["impl"], False)
        for n in fn:            
            if(n.content is not None and len(n.content)>0):
                question = cntxt + cntxt_nodes + self.parser.to_text(n, indent, False,"q")
                answer  = cntxt +cntxt_nodes +self.parser.to_text(n, indent, False,"a")
                self.addQA(question,answer)

    def nodeToQA(self, node,indent,ctx=""):
        self.addFnQuestions(node,indent,ctx)
        self.addImplQuestions(node,indent,ctx)
    
    def getQA(self):
        self.nodeToQA(self.parser.root,0)
        Mod = self.parser.find_nodes(self.parser.root,["mod"], False)
        ctx = self.buildContext(self.parser.root,["use","struct","const","enum","trait"])
        for n in Mod:
            nod = ctx + self.parser.to_text(n, 0, False,"q")
            print(nod)
            self.nodeToQA(n,1,nod)
        return self.qa
            
