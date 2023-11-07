from ctransformers import AutoModelForCausalLM,AutoConfig,AutoTokenizer
from transformers import  TextIteratorStreamer
import torch
import gradio as gr
from threading import Thread


hub_name = "StarkWizard/Mistral-7b-instruct-cairo-instruct-GGUF"
model_file = "Mistral-7b-instruct-cairo-instruct.Q4_k.gguf"
DEVICE,hw,layers = ("cpu",True,0) if torch.cuda.is_available() else ("cpu",False,0)





print("loading LLM")
# Load model 
config = AutoConfig.from_pretrained("TheBloke/Mistral-7B-v0.1-GGUF")

config.max_seq_len = 4096
config.max_answer_len= 1024

model = AutoModelForCausalLM.from_pretrained(hub_name, model_file=model_file, model_type="mistral", gpu_layers=layers,
        config=config,
            compress_pos_emb=2,
            top_k=4000,
            top_p=0.99,
            temperature=0.0001,
            do_sample=True,
           

)
system_prompt = """A student asks you a question about Cairo 1. Provide a concise answer to the student's questions,do not expand the subject of the question, do not introduce any new topics or new question not provided by the student.
        Make sure the explanations never be longer than 300 words.Don’t justify your answers. Don’t give information not mentioned in the CONTEXT INFORMATION.provide only one solution
"""

def fmt_history(history) -> str:
    
    return "\n".join(["User: \"{usr_query}\", Assistant: \"{your_resp}\"".format(
        usr_query=usr_query.replace("\n",""), your_resp=your_resp.format("\n",""))
        for usr_query, your_resp in history])

    

def run_generation(user_text, top_p, temperature, top_k, max_new_tokens,sys_prompt):

    text =f"""
    [INST]
        <<SYS>> 
        {sys_prompt}
        <</SYS>>    
        Question: I'm working in Cairo 1 :
        {user_text} 
    [/INST]
    """
    print(text)
    model_output = ""
    for text in model(text, stream=True,max_new_tokens=max_new_tokens,top_p=top_p,top_k=top_k,temperature=temperature):
       model_output += text
       yield model_output


    return model_output



def reset_textbox():
    return gr.update(value='')

with gr.Blocks() as demo:
    duplicate_link = "https://huggingface.co/spaces/joaogante/transformers_streaming?duplicate=true"
    gr.Markdown(
        "# 🔥 Mistral Cairo 🔥\n"
        f"[{hub_name}](https://huggingface.co/{hub_name})\n\n"

    )

    with gr.Row():
        with gr.Column(scale=1):
            max_new_tokens = gr.Slider(
                minimum=1, maximum=2000, value=2000, step=1, interactive=True, label="Max New Tokens",
            )
            top_p = gr.Slider(
                minimum=0.05, maximum=1.0, value=0.97, step=0.05, interactive=True, label="Top-p (nucleus sampling)",
            )
            top_k = gr.Slider(
                minimum=40, maximum=5000, value=40, step=10, interactive=True, label="Top-k",
            )
            temperature = gr.Slider(
                minimum=0.01, maximum=0.4, value=0.001, step=0.1, interactive=True, label="Temperature",
            )
            prompt_box = gr.Textbox( label="System Prompt",
                value=system_prompt,
                lines=10,
                max_lines=10,
                show_label=True
            )


        with gr.Column(scale=4):

            chatbot = gr.Chatbot()
            msg = gr.Textbox()
            clear = gr.Button("Clear")
            
            def user(user_message, history):
                return "", history + [[user_message, None]]
            def respond(history, top_p, temperature, top_k, max_new_tokens,prompt_box):
                message = history[-1][0]
                print(f"User: {message}")
                print(f"top_p {top_p}, temperature {temperature}, top_k {top_k}, max_new_tokens {max_new_tokens}")
                bot_message = run_generation(message,top_p, temperature, top_k, max_new_tokens,prompt_box)
                for character in bot_message:
                    history[-1][1] = character
                    print(character, end="", flush=True)
                    yield history

        
            msg.submit(user, [msg, chatbot], [msg, chatbot], queue=False).then(respond, [chatbot,top_p, temperature, top_k, max_new_tokens,prompt_box], chatbot)
            clear.click(lambda: None, None, chatbot, queue=False)


    
demo.queue()
demo.launch()


