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


# API key

You will require an API from Anthropic for this project.
It needs to be exported as an environment variable named `ANTHROPIC_API_KEY`.

> [!IMPORTANT]
> **Please do this export yourself. There is no .env file.
> I didn't want to add a dependency from an unknown source just to read a single enviroment variable.**


# Getting the RTL files

The RTL files are available at [svabench_test_designs](https://github.com/deebakkarthi/svabench_test_designs)

Run `scripts/fetch_benchmarks.sh`

This will download the RTL files into the `bench/` folder


# `scripts`

This is a collection of the useful scripts that is auxillary to the main
benchmark. The main benchmark will be a single python program.


# `prompts`
This folder contains the prompt given to the LLM. The prompt's objective
to be as clear as possible while not inducing any bias. This bias can be both
ways - positive and negative. The instructions are very clear but very brief.
We want to the inherent procivilities of the model and then modify the prompt
to optimize/fix. We wanted to avoid premature optimization which would also
cause noisy benchmarks.

# Goal
The goal of the benchmark is to evaluate purely the RTL2SVA capabilities of a
model. We don't concern ourselves with bug hunting or golden designs. Given
some RTL design, can the model convert the functionality into assertions?
Note that this also implies that bugs will be carried over but this is
intentional.

