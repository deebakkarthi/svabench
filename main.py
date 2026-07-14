#!/usr/bin/env python3

import anthropic


def main():

    client = anthropic.Anthropic()

    message = client.messages.create(
        max_tokens=1024,
        model="claude-haiku-4-5",
        messages=[
            {
                "role": "user",
                "content": "Hello, Seaman",
            }
        ],
    )

    for block in message.content:
        if block.type == "text":
            print(block.text)
    return


if __name__ == "__main__":
    main()
