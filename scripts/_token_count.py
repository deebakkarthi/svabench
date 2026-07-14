#!/usr/bin/env python3
"""A script that returns the number of claude tokens

The input is read from stdin by default if no cmdline args are passed
If a cmdline args are passed, they are treated as path and concatenated
together to return the total number of tokens
"""

import sys
import anthropic

progname: str


def token_count(input_str: str) -> int:
    client = anthropic.Anthropic()
    response = client.messages.count_tokens(
        model="claude-opus-4-8",
        messages=[{"role": "user", "content": input_str}],
    )
    return response.input_tokens


def help():
    global progname
    print(f"""Usage: {progname} [-h | FILEs]
    -h\t\tPrint this help message
    FILEs\tFiles to read as input

    By default stdin is read""")
    return


def main():
    global progname
    progname = sys.argv[0]
    input_str = ""

    if len(sys.argv) > 1:
        if sys.argv[1] == "-h":
            help()
            sys.exit(0)
        else:
            for file in sys.argv[1:]:
                with open(file, "rb") as f:
                    # Weird issue with one of the bench files in arith/tate
                    # TODO: Fix the byte with the error in the file itself
                    # so that we can just use read() with "r" instead of "rb"
                    input_str += f.read().decode(errors="ignore")
    else:
        input_str += sys.stdin.read()

    print(token_count(input_str))
    return


if __name__ == "__main__":
    main()
