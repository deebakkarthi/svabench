# svabench
SystemVerilog Assertion Generation Benchmark for Large Language Models


# Python Enviroment
Though Claude's SDK is available in many languages, this project uses
`python`. Hence we need to setup a virtual environment. Please make sure that
you have `python>=3.9` as `anthropic` only works on that.

```bash
python3 -m venv .venv
source .venv/bin/activate
```
Run `which python` to make sure that path returned is the current directory.

## Install `anthropic`

```bash
pip3 install anthropic
```
For now this shall work. But in the future when we add other dependencies, run

```bash
pip3 install -r requirements.txt
```
