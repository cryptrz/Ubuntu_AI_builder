# Linux AI builders for Ubuntu and Fedora

## Summary

These scripts automate the installation (tested on Ubuntu 24.04.4 and Fedora 43), set up and execution of the following: 
- NVIDIA drivers
- Docker
- Ollama
- OpenWeb UI

The objectif is to run your favorite LLMs locally and interact with them in a web browser. 

## Choose your model

By default, I chose to run llama3.2 by default. If you prefer another one, you can open a script and go to this line: 

`ollama pull llama3.2`

You can replace `llama3.2` with another available model. You can list them with this command:

`curl -s https://ollama.com/library | grep -oP '(?<=href="/library/)[^"]+' | sort -u`.

Or you can go directly to this page: 

https://ollama.com/library

## Preparation

Ubuntu: `sudo chmod +x Ubuntu_AI_builder.sh`

Fedora: `sudo chmod +x Fedora_XFCE_AI_builder.sh`

## Execution

Ubuntu: `sudo ./Ubuntu_AI_builder.sh`

Fedora: `Fedora_XFCE_AI_builder.sh`
