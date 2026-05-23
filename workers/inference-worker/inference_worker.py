import os
import time
from typing import Any, Dict
from iii import InitOptions, Logger, register_worker
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

iii = register_worker(
    os.environ.get("III_URL", "ws://localhost:49134"),
    InitOptions(worker_name="inference"),
)

model_id = "ggml-org/gemma-3-270m-GGUF"
gguf_file = "gemma-3-270m-Q8_0.gguf"

tokenizer = AutoTokenizer.from_pretrained(model_id, gguf_file=gguf_file)
model = AutoModelForCausalLM.from_pretrained(model_id, gguf_file=gguf_file)

def run_inference_handler(payload: Dict[str, Any]) -> Dict[str, Any]:
    messages = payload.get("messages", [])
    last_message = messages[-1]["content"].strip() if messages else ""
    prompt = f"Q: {last_message}\nA:"
    inputs = tokenizer(prompt, return_tensors="pt")
    input_len = inputs["input_ids"].shape[-1]
    with torch.no_grad():
        output = model.generate(
            **inputs,
            max_new_tokens=15,
            do_sample=False,
            repetition_penalty=2.0,
            pad_token_id=tokenizer.eos_token_id,
        )
    new_tokens = output[0][input_len:]
    raw_text = tokenizer.decode(new_tokens, skip_special_tokens=True).strip()
    return {"response": raw_text.split('\n')[0].strip()}

iii.register_function("inference::run_inference", run_inference_handler)
print("Inference worker started - listening for calls", flush=True)

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("Shutting down...")