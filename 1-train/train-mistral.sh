#!/bin/bash
python train.py --model_name="mistralai/Mistral-7B-Instruct-v0.2" --new_model="StarkWizard/Mistral-7b-instruct-cairo-PEFT" --lr=2e-5   q_proj k_proj v_proj o_proj gate_proj --epochs=30