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
