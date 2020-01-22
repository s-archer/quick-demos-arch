 # Automation 101 Student Environment
 
 ## Overview

 These playbooks are provided to spin up a quick workshop environment in AWS, and also to easily destroy the environment when done.  The configuration builds and destroys the following:

 - VNET or VPC
 - Subnets (Management and Dataplane)
 - Internet Gateway
 - Routing
 - A number of BIG-IPs deployed with 2 NICs 

 In *AWS*, the playbook will login to the deployed BIG-IPs and change/enable password authentication.  


## How to run...

These playbooks were tested with Ansible 2.8.1 (other versions may work too).  If you have ansible installed, you can run the playbooks with: 
 
 ```ansible-playbook playbook-name```

 or if using valut:

  ```ansible-playbook playbook-name --ask-vault-pass```

 e.g. 

```ansible-playbook main-create-playbook.yaml --ask-vault-pass```

## Prerequisites


The AWS & Azure Ansible modules require the following Python packages to be installed ([sudo]pip install <package name>):

 - python >= 2.6
 - botocore >= 1.5.45
 - boto
 - boto3
 - nose
 - tornado
 - paramiko
 - f5-sdk


To allow Ansible to SSH to hosts (specifically for BIG-IPs in AWS, in order to change initial password and enable password authentication), you will need an SSH key pair... and you might need to disable host_key_checking in the Ansible config file:

 - create an SSH key pair in PEM format (or use your existing key pair e.g. ~/.ssh/id_rsa[.pub])
 -- ```ssh-keygen -t rsa``` # Accept the default names and do not set a passphrase.  If you're running Python 2.7, you might need to run ```ssh-keygen -t rsa -m PEM``` and append .pem to the filename.\
 - create ansible.cfg (if it doesn't exist) and add the following four lines (substituting <key file name> with your SSH key file path/name):

```
[defaults]
private_key_file = <key file name>
host_key_checking = False
callback_whitelist = profile_tasks, timer
```
The last line above adds timing information to your playbook, which improves a demo.

 - You can place the ansible.cfg file in the same directory as your playbook, thus providing playbook specific settings, or you can place it in the /etc/ansible/ folder, which provides global settings..

### AWS Configuration Notes


In AWS you will need to create an IAM for programmatic access (or if you don't have permissions, get someone to create one for you).  The IAM will provide you with an EC2 Access Key and Secret Key.  You will need to place these in a variables file named aws_creds.yaml (and update path in the 'vars_files' section of the playbooks) with the following variables:

```
ec2_access_key: "<--your-key-here-->"
ec2_secret_key: "<--your-secret-here-->"
```

You will also need a file named big_creds.yaml (and update path in the 'vars_files' section of the playbooks) with the following variables:

```
bigip_user: "--your-username-here--"
bigip_pass: "--your-password-here--"
```

And, in EC2, you will need to go to 'Key Pairs' and 'Import Key Pair', in each region you want to use.  That is to say, import the 'public' half of the PEM format SSH Key Pair you referenced in the Ansible Prerequisites section above:


### IMPORTANT!!  
Make sure your creds files are not in ANY of your git repo folders.
In my example, I have the following directory structure.  You can see that the creds file resides outside of my git repo (the values are also encrypted with ansible vault):

```bash
Root
├── creds
│   ├── aws_creds.yaml
│   ├── azure_creds.yaml
│   └── big_creds.yaml
└── quick-demos
    ├── README.md
    ├── ansible-aws
    │   ├── CREATE-failover-samenet-api-exist-payg.yaml
    │   ├── DELETE-failover-samenet-api-exist-payg.yaml
    │   └── vars.yaml
    └── ansible-azure
        ├── CREATE-azure-arm-ha-api-exist-payg-UDR.yaml
        ├── DELETE-azure-arm-ha-api-exist-payg-UDR.yaml
        └── vars.yaml
```