#!/usr/bin/env python3
import boto3
import base64
import os
import argparse


def get_base64_key(keyid, plaintext, region):
    client = boto3.client('kms', region_name=region)
    response = client.encrypt(
    KeyId=keyid,
    Plaintext=plaintext
    )

    ciphertext = response['CiphertextBlob']
    return base64.b64encode(ciphertext)


parser = argparse.ArgumentParser()
parser.add_argument("-p", "--password", help="password to be encrypted", type=str)
parser.add_argument("-k", "--kms", help="KMS key alias", type=str)
parser.add_argument("-r", "--region", help="aws region", type=str)
args = parser.parse_args()
print(get_base64_key(args.kms, args.password, args.region).decode('ascii'))
