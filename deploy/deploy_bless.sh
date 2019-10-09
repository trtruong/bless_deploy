#!/usr/bin/env bash
set -ex
##############################
## Deploying BLESS function ##
##############################
AWS_REGION=$1
REGIONS=`aws ec2 describe-regions --region ${AWS_REGION}| jq -r '.Regions[].RegionName'`
isValidRegion=`echo "${REGIONS[@]}" | grep -o ${AWS_REGION} | wc -w`

### Require a region to execute
if [[ $# -eq 0 ]] || [[ $isValidRegion -eq 0 ]] ; then
    echo "execute $0 with AWS region name"
    exit 1
fi

### Deploying Terraform ###
function deployTerraform() {
  pushd ${1} || exit 1
  terraform init
  terraform workspace select $2 || terraform workspace new $2
  terraform plan -out $2.plan
  if [ $? -eq 0 ]; then
    terraform apply $2.plan
  else
    echo "terraform plan failed"
    exit 1
  fi
  popd
}

## Applying terraform to create KMS key ###
deployTerraform "terraform/kms-key" $AWS_REGION

## Getting Netflix source code from public repo ###
[ -f '0.4.0.zip' ] || wget https://github.com/Netflix/bless/archive/0.4.0.zip
[ -d 'bless-0.4.0' ] || unzip 0.4.0.zip
ln -s bless-0.4.0 bless || true
[ -d 'bless/lambda_configs' ] || mkdir -p bless/lambda_configs

## Generating SSH key-pair for lambda function to use ###
if [ ! -f "lambda_configs/bless-ca-${AWS_REGION}.pub" ]; then
  echo "!!!!! A set of New SSH keypair is being generated !!!!!!"
  SSH_PASSPHRASE=`date +%s | sha256sum | base64 | head -c 64`
  echo $SSH_PASSPHRASE
  ssh-keygen -t rsa -b 4096 -f lambda_configs/bless-ca-$AWS_REGION -C "SSH CA Key $AWS_REGION" -m PEM -N $SSH_PASSPHRASE
  PRIVATE_KEY=`cat lambda_configs/bless-ca-$AWS_REGION`
  ## Change permission so lambda function can read private key
  chmod 0644 lambda_configs/bless-ca-$AWS_REGION
  cp lambda_configs/bless-ca-$AWS_REGION lambda_configs/bless-ca-$AWS_REGION.pub bless/lambda_configs/

  ## Storing passphrase and private key in AWS parameters store ##
  aws ssm put-parameter --name "/BLESS/ssh-keypairs/$AWS_REGION/passphrase" --value "$SSH_PASSPHRASE" --type "SecureString" --overwrite --region ${AWS_REGION}
  aws ssm put-parameter --name "/BLESS/ssh-keypairs/$AWS_REGION/private_key" --value "$PRIVATE_KEY" --type "SecureString" --overwrite --region ${AWS_REGION}
else
  SSH_PASSPHRASE=`aws ssm get-parameter --name "/BLESS/ssh-keypairs/$AWS_REGION/passphrase" --with-decryption --region ${AWS_REGION} | jq -r '.Parameter.Value'`
  aws ssm get-parameter --name "/BLESS/ssh-keypairs/$AWS_REGION/private_key" --with-decryption --region ${AWS_REGION} | jq -r '.Parameter.Value' > lambda_configs/bless-ca-$AWS_REGION
fi
## Calling KMS to encrypt SSH passphrase ##
ENCRYPTED_PW=`./encryptKey.py -k "alias/BLESS-$AWS_REGION" -p $SSH_PASSPHRASE -r $AWS_REGION`
echo $ENCRYPTED_PW

## Preparing Netflix Bless lambda function configuration ##
## Copy bless_request_user with change adapt to our username convention ##
cp bless_request_user.py bless/bless/request/
pushd bless/lambda_configs || exit 1
cp ../../lambda_configs/bless-ca-${AWS_REGION}* ./
cp ../bless/config/bless_deploy_example.cfg ./bless_deploy.cfg
gsed -i '/us-west-2_password/d' bless_deploy.cfg
gsed -i 's/certificate_validity_after_seconds.*/certificate_validity_after_seconds = 600/' bless_deploy.cfg
gsed -i 's/certificate_validity_before_seconds.*/ccertificate_validity_before_seconds = 600/' bless_deploy.cfg
gsed -i "s|us-east-1_password.*|${AWS_REGION}_password = $ENCRYPTED_PW|" bless_deploy.cfg
gsed -i "s|ca_private_key_file.*|ca_private_key_file = bless-ca-$AWS_REGION|" bless_deploy.cfg
popd

pushd bless || exit 1
[ -d 'aws_lambda_libs' ] || make lambda-deps
make publish
popd

### Deploying Lambda function terraform ###
deployTerraform "terraform/bless-lambda" $AWS_REGION

#### Cleanup Netflix source code ####
rm -rf bless 0.4.0.zip bless-0.4.0
