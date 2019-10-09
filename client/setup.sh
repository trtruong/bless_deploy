#!/bin/bash
#
#
# Sets up environment for Bless Client
#
#
#

echo "============================================="
echo "Configuring your environment for Bless Client"
echo "============================================="

case `uname` in
  "Darwin" )
    type brew
    if [ $? -ne 0 ]
    then
      echo "brew not found. Please install at http://brew.sh"
      exit 1
    else
      echo "brew already installed..."
    fi

    type python3
    if [ $? -ne 0 ]
    then
      echo "python3 not found. Installing.."
      brew install python3
      if [ $? -ne 0 ]
      then
        echo "failed to install python3.."
        exit 1
      fi
    else
      echo "python3 already installed..."
    fi

    type pip3
    if [ $? -ne 0 ]
    then
      echo "pip3 not found. Please correct."
      exit 1
    else
      echo "pip3 already installed..."
    fi

    type aws
    if [ $? -ne 0 ]
    then
      echo "awscli not found. Installing.."
      pip3 install awscli
      if [ $? -ne 0 ]
      then
        echo "failed to install awscli.."
        exit 1
      fi
    else
      echo "awscli already installed..."
    fi

    pip3 show boto3
    if [ $? -ne 0 ]
    then
      echo "Installing boto.."
      pip3 install boto3
      if [ $? -ne 0 ]
      then
        echo "failed to install boto.."
        exit 1
      fi
    else
      echo "boto already installed.."
    fi

    pip3 show boto3
    if [ $? -ne 0 ]
    then
      echo "Installing boto3.."
      pip3 install boto3
      if [ $? -ne 0 ]
      then
        echo "failed to install boto3.."
        exit 1
      fi
    else
      echo "boto3 already installed.."
    fi

    pip3 show bs4
    if [ $? -ne 0 ]
    then
      echo "Installing BeutifulSoup4.."
      pip3 install bs4
      if [ $? -ne 0 ]
      then
        echo "failed to install bs4.."
        exit 1
      fi
    else
      echo "bs4 already installed.."
    fi

    pip3 show requests
    if [ $? -ne 0 ]
    then
      echo "Installing requests.."
      pip3 install requests
      if [ $? -ne 0 ]
      then
        echo "failed to install requests.."
        exit 1
      fi
    else
      echo "requests already installed.."
    fi

    echo "symlinking okta to ~/.aws/okta"
    mkdir -p ~/.aws
    ln -sf ${PWD}/okta ~/.aws/okta
  ;;
  Linux )
    yum install -y epel-release
    which python3
    if [ $? -ne 0 ]
    then
      echo "python3 not found. Installing.."
      yum install -y python36.x86_64
      if [ $? -ne 0 ]
      then
        echo "failed to install python3.."
        exit 1
      fi
    else
      echo "python3 already installed..."
    fi

    which pip3
    if [ $? -ne 0 ]
    then
      echo "pip3 not found. Please correct."
      yum install -y python36-pip
      ln -s /usr/local/bin/pip3.6 /usr/local/bin/pip3
      /usr/local/bin/pip3.6 install -U pip
    else
      echo "pip3 already installed..."
    fi

    which aws
    if [ $? -ne 0 ]
    then
      echo "awscli not found. Installing.."
      /usr/local/bin/pip3.6 install awscli
      if [ $? -ne 0 ]
      then
        echo "failed to install awscli.."
        exit 1
      fi
    else
      echo "awscli already installed..."
    fi

    /usr/local/bin/pip3.6 show boto3
    if [ $? -ne 0 ]
    then
      echo "Installing boto3.."
      /usr/local/bin/pip3.6 install boto3
      if [ $? -ne 0 ]
      then
        echo "failed to install boto3.."
        exit 1
      fi
    else
      echo "boto3 already installed.."
    fi

    /usr/local/bin/pip3.6 show bs4
    if [ $? -ne 0 ]
    then
      echo "Installing BeutifulSoup4.."
      /usr/local/bin/pip3.6 install bs4
      if [ $? -ne 0 ]
      then
        echo "failed to install bs4.."
        exit 1
      fi
    else
      echo "bs4 already installed.."
    fi

    /usr/local/bin/pip3.6 show requests
    if [ $? -ne 0 ]
    then
      echo "Installing requests.."
      /usr/local/bin/pip3.6 install requests
      if [ $? -ne 0 ]
      then
        echo "failed to install requests.."
        exit 1
      fi
    else
      echo "requests already installed.."
    fi
      exit 1
    ;;
  * )
    echo `uname` "is an unsupported OS. Please manually install python3, awscli and the boto, boto3, bs4 and requests modules"
    exit 1
  ;;
esac
