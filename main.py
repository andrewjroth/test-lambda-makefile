import requests


def lambda_handler(event, context):
    print("Hello World")
    res = requests.get("http://example.com")
    print(f"Response was {len(res.text)} long")


if __name__ == "__main__":
    lambda_handler(None, None)

