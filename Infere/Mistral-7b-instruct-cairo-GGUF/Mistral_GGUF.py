from ctransformers import AutoModelForCausalLM,AutoConfig

import torch
import gradio as gr

hub_name = "StarkWizard/Mistral-7b-instruct-cairo-instruct-GGUF"
model_file = "Mistral-7b-instruct-cairo-instruct.Q4_k.gguf"
DEVICE,hw,layers = ("cuda",True,50) if torch.cuda.is_available() else ("cpu",False,0)






def load_ll():
    print("loading LLM")
    # Load model 
    config = AutoConfig.from_pretrained("TheBloke/Mistral-7B-v0.1-GGUF")

    config.max_seq_len = 4096
    config.max_answer_len= 1024

    llm = AutoModelForCausalLyield(hub_name, model_file=model_file, model_type="mistral", gpu_layers=layers,
            config=config,
                compress_pos_emb=2,
                top_k=4000,
                top_p=0.99,
                temperature=0.001,

    )
    return llm

def fmt_history(history) -> str:
    
    return "\n".join(["User: \"{usr_query}\", Assistant: \"{your_resp}\"".format(
        usr_query=usr_query.replace("\n",""), your_resp=your_resp.format("\n",""))
        for usr_query, your_resp in history])

    

def llm_func(message, chat_history=[]):
    text =f"""[INST]
        <<SYS>>
        Provide a concise answer to the questions<SYS>>

        Question: I'm working in Cairo 1 :{message} 
        [/INST]"""
    input_ids = LLM.tokenizer.encode(text, return_tensors="pt").to(LLM.device)  # Ensure the tokens are on the correct device

    # Generate a response
    with torch.no_grad():  # Ensure no gradients are calculated
        output = LLM.generate(input_ids, max_length=config.max_seq_len)
    
    # Decode the generated ids to a text string
    response = LLM.tokenizer.decode(output[0], skip_special_tokens=True)

    return response


    
title = 'Mistral Cairo 1.0 GGUF'
examples = [
    'Create an array and append domestic animal names',
    'How can you print a variable\'s value in Cairo? Give a full sample',
    ]

LLM = load_ll()
gr.ChatInterface(
    fn = llm_func,
    title = title,
    examples = examples
).launch()