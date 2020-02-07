 # NGINX Public Cloud Demo Environments
 
 ## Overview

 This playbook is provided to spin up a quick demo environment up in AWS, and also to easily destroy the demo when done.  The configuration builds and destroys the following:

 - VNET or VPC
 - Subnets (Management and Dataplane)
 - Internet Gateway
 - Routing
 - An AWS RDS DB Instance  
 - NGINX Controller 3.x



## How to run...

This playbook requires Ansible 2.8.1.  If you have ansible installed, you can run the playbooks with: 
 
 ```ansible-playbook playbook-name```

 or if using valut:

  ```ansible-playbook playbook-name --ask-vault-pass```

 e.g. 

```ansible-playbook main-create.yaml --ask-vault-pass```

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
 - azure


To allow Ansible to SSH to hosts deployed into AWS, you will need an SSH key pair... and you might need to disable host_key_checking in the Ansible config file:

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


### General Configuration Notes

You will need a few more variables in your creds.yaml file (and update path in the 'vars_files' section of the playbooks), depending on what/where you are deploying:

For Azure plays:

```
bigip_azure_user: "--your-username-here--"
bigip_azure_pass: "--your-password-here--"

az_subs_id: "<--your-id-here-->"
az_client_id: "<--your-id-here-->"
az_secret: "<--your-secret-here-->"
az_tenant: "<--your-tenant-here-->"
```

For AWS plays:

```
bigip_user: "--your-username-here--"
bigip_pass: "--your-password-here--"

ec2_access_key: "<--your-key-here-->"
ec2_secret_key: "<--your-secret-here-->"
```


For NGINX Controller 3 plays:

```
ses_smtp_user: <Register for AWS SES - User> 
ses_smtp_pass: <Register for AWS SES - Pass>

rds_user: <rds username>
rds_pass: <rds password>

nginx_user: <user>
nginx_pass: <password>

nginx_fname: <controller user first name>
nginx_sname: <controller user surname>
nginx_email: <controller user email>
nginx_noreply_email: <controller no-reply email>

```

For F5 CS Beacon plays:

```
f5_beacon_token: <token>
```

For Slack Channel output in plays:

```
slack_token: <token>
```

### NGINX Configuration Notes

The playbook for NGINX Controller 3.x installation requires AWS SES (Simple Email Service), so you may need to regsiter for that, unless you have an alternative SMTP relay service.  If you want to use the Slack feature, then you will need an account and token.

### AWS Configuration Notes


In AWS you will need to create an IAM for programmatic access (or if you don't have permissions, get someone to create one for you).  The IAM will provide you with an EC2 Access Key and Secret Key.  You will need to place these in a variables file named creds.yaml (and update path in the 'vars_files' section of the playbooks) with the following variables:

```
ec2_access_key: "<--your-key-here-->"
ec2_secret_key: "<--your-secret-here-->"
```

And, in EC2, you will need to go to 'Key Pairs' and 'Import Key Pair', in each region you want to use.  That is to say, import the 'public' half of the PEM format SSH Key Pair you referenced in the Ansible Prerequisites section above:


### IMPORTANT!!  
Make sure your creds files are not in ANY of your git repo folders.
In my example, I have the following directory structure.  You can see that the creds file resides outside of my git repo (the values are also encrypted with ansible vault):

```bash
Root
├── creds
│   └── creds.yaml
└── quick-demos-arch
    ├── README.md
    ├── ansible-nginx...
    │   ├── main-create.yaml
    │   ├── main-delete.yaml
    │   └── <folders>
    └── ansible-with...
        ├── main-create.yaml
        ├── main-delete.yaml
        └── <folders>
```


### Azure Configuration Notes

In order to configure API access to your Azure account you will need to do the following:

 - within the Azure Active Directory create a new 'App' on the 'App Registration' page.
 - within the new 'App' you just created, create a new Client Secret.  The value must be saved, as you cannot retrieve it again:  
   - this value is your "{{ az_secret }}".
 - the 'App' overview page will provide:
   - the 'Application (client) ID' is your "{{ az_client_id }}"
   - the 'Directory (tenant) ID' is your "{{ az_tenant_id }}"
 - 'Expose an API' by adding a 'Scope' and a 'Client Application', with the latter referencing your 'Application (client) ID'.
 - if you type 'subscriptions' into the search box at the top of the Azure Portal, you can find your Subscription ID:
  - the 'Subscription ID' is your "{{ az_subs_id }}"
- within your subscription, go to 'Access Control (IAM)' and 'Role Assignments'.  Add a Role Assignment and give your 'App' the 'Contributor Role'. 

You will need the details gathered above to populate a variables file. Create a file named creds.yaml (and update path in the 'vars_files' section of the playbooks) and populate with the following variables and insert your values:

```
az_subs_id: "<--your-id-here-->"
az_client_id: "<--your-id-here-->"
az_secret: "<--your-secret-here-->"
az_tenant: "<--your-tenant-here-->"
```


