#!/usr/bin/env python3

"""bless_client
A sample client to invoke the BLESS Lambda function and save the signed SSH Certificate.

Usage:
  bless_client.py -h <bastion-host>
                  -k <key to sign, default to id_rsa>
                  -r <region, default to us-east-2>
"""
import json
import stat
import sys
import argparse
import boto3
from botocore.exceptions import NoCredentialsError
import os
from requests import get


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument( "-i", "--ip", help="Bastion Host's IP to connect", required=True )
  parser.add_argument( "-k", "--key", help="Public key to be sign by BLESS", default='~/.ssh/id_rsa.pub' )
  parser.add_argument( "-t", "--token", help="ksmauth_token if being use", required=False)
  parser.add_argument("-r", "--region", help="AWS Region where BLESS lambda lives", default='us-east-2')
  parser.add_argument("-s", "--source", help="Source IP address", default=get('https://api.ipify.org').text)
  args = parser.parse_args()

  try:
    client = boto3.client('sts')
    response = client.get_caller_identity()
  except NoCredentialsError as error:
    #print("Unexpected error: %" %e)
    print(error["Error"]['Code'])
    if error.response['Error']['Code'] == 'NoCredentialsError':
      print("Please login to AWS via Okta cli")
    else:
      raise error
  remote_usernames = bastion_user = response["UserId"].split(":")[1].split("@")[0].lower()
  #bastion_ips = ip = get('https://api.ipify.org').text
  bastion_ips = ip = args.source
  lambda_function_name = 'BLESS-' + args.region
  bastion_user_ip = args.ip
  bastion_command = 'ssh'
  certificate_filename = os.path.expanduser(args.key).strip('.pub') + "-cert"
  region = args.region

  print(os.path.expanduser(args.key))

  with open(os.path.expanduser(args.key), 'r') as f:
      public_key = f.read().strip()

  payload = {'bastion_user': bastion_user, 'bastion_user_ip': bastion_user_ip,
             'remote_usernames': remote_usernames, 'bastion_ips': bastion_ips,
             'command': bastion_command, 'public_key_to_sign': public_key}

  if args.token is not None:
      payload['kmsauth_token'] = argv[9]

  payload_json = json.dumps(payload)

  print('Executing:')
  print('payload_json is: \'{}\''.format(payload_json))
  lambda_client = boto3.client('lambda', region_name=region)
  response = lambda_client.invoke(FunctionName=lambda_function_name,
                                  InvocationType='RequestResponse', LogType='None',
                                  Payload=payload_json)
  print('{}\n'.format(response['ResponseMetadata']))

  if response['StatusCode'] != 200:
      print ('Error creating cert.')
      return -1

  payload = json.loads(response['Payload'].read())

  if 'certificate' not in payload:
      print(payload)
      return -1

  cert = payload['certificate']

  with os.fdopen(os.open(certificate_filename, os.O_WRONLY | os.O_CREAT, 0o600),
                 'w+') as cert_file:
      cert_file.write(cert)

  # If cert_file already existed with the incorrect permissions, fix them.
  file_status = os.stat(certificate_filename)
  if 0o600 != (file_status.st_mode & 0o777):
      os.chmod(certificate_filename, stat.S_IRUSR | stat.S_IWUSR)

  print('Wrote Certificate to: ' + certificate_filename)


if __name__ == '__main__':
    main()
