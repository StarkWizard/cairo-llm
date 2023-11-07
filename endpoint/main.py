from flask import Flask, request, Response,render_template
from langchain.llms import HuggingFacePipeline
from langchain.callbacks.streaming_stdout import StreamingStdOutCallbackHandler
import torch
from transformers import AutoTokenizer, TextStreamer, GenerationConfig, BitsAndBytesConfig,pipeline
from attention_sinks import AutoModelForCausalLM

_port = 5000
model_name = "mistralai/Mistral-7B-Instruct-v0.1"
hub_name = "StarkWizard/Mistral-7b-instruct-cairo-instruct-AWQ"


app = Flask(__name__)


# loading tokenizer
tokenizer = AutoTokenizer.from_pretrained(model_name, use_fast=True)
tokenizer.pad_token = tokenizer.eos_token


#loading model in 4bit
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype="float16",
    bnb_4bit_use_double_quant=True,
)
model = AutoModelForCausalLM.from_pretrained(pretrained_model_name_or_path=hub_name,
                                             trust_remote_code=True,
                                             device_map={"": 0},
                                             attention_sink_size=4,
                                             quantization_config=bnb_config,
                                            attention_sink_window_size=252, # <- Low for the sake of faster generation
                                             )
model.eval()

#creating the langchain model

pipe = pipeline(
    "text-generation", model=model, tokenizer=tokenizer, max_new_tokens=300, batch_size=8
)
llm = HuggingFacePipeline(pipeline=pipe)
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/infer', methods=['GET'])
def infer():
    print("here")
    prompt = request.args.get('prompt')
    print("There")
    print("there",prompt)

    temperature = float(request.args.get('temperature', 0.4))  # Default temperature is 0.7\
    if temperature == 0:
        temperature=0.01
    
    text =f"""[INST]
    <<SYS>>
    provide only one solution and no other possible solution, stick to the main topic, do not introduce any new topics or new question not provided by the student.
    Make sure the explanations never be longer than 100 words.Don’t justify your answers. <SYS>>

    Question: I'm working in Cairo 1 :{prompt} 
    [/INST]"""

    response = llm.generate([text], 
        use_cache=True,
 
 
            pad_token_id=tokenizer.pad_token_id,
            eos_token_id=tokenizer.eos_token_id,
            temperature=temperature
            )
    print(response)
    generated_text = response.generations[0][0].text
    print(generated_text)
    return  Response(generated_text, mimetype='text/plain; charset=utf-8')



if __name__ == '__main__':
    app.run(port=_port,debug=True)
