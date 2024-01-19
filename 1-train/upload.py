from transformers import AutoModel, AutoTokenizer

from huggingface_hub import login
login()

# Chemin vers votre modèle local
model_path="./StarkWizard/Mistral-7b-instruct-cairo-PEFT"

# Charger le modèle
model = AutoModel.from_pretrained(model_path)

# Charger le tokenizer associé
tokenizer = AutoTokenizer.from_pretrained(model_path)

from huggingface_hub import push_to_hub

# Nom de votre modèle sur le hub
model_name ="StarkWizard/Mistral-7b-instruct-cairo-PEFT"


model.push_to_hub(model_name)
tokenizer.push_to_hub(model_name)