 # Arch's Personal Use F5 Public Cloud Demo Environments
 
 ## Overview

 These playbooks are provided to spin up a quick demo environment up in Azure or AWS, and also to easily destroy the demo when done.  The configuration builds and destroys the following:

 - VNET or VPC
 - Subnets (Management and Dataplane)
 - Internet Gateway
 - Routing
 - A pair of BIG-IPs deployed with 2 NICs in HA 

 In AWS, the playbook will login to the deployed BIG-IPs and change/enable password authentication.  In Azure, passwords are enabled by default.

 What these playbooks don't provide (yet):

 - Any test application server (I plan to automate a microservices app)
 - AS3 configuration to create a virtual server and pool (in progress with peering playbook)
 - Automated TLS certs/keys
 - F5 Cloud Services GSLBaaS (in progress with peering gslb playbook)
 - F5 Silverline WAFaaS


## IMPORTANT!

DO NOT put credentials in any file of folder contained in this repo!


## Configuration Notes

These playbooks require Ansible 2.8.1.

If you have ansible installed, you can run the playbooks with: 
 
 ```ansible-playbook playbook-name```

 e.g. 

```ansible-playbook CREATE-azure-arm-ha-api-exist-payg-UDR.yaml```


There are instructions contained within each playbook, and within the vars files.  The instructions in the playbook tell you how to declare your credentials.


### AWS Configuration Notes

To allow Ansible to SSH to BIG-IPs in AWS (to change initial password and enable password authentication), you might need to disable host_key_checking in the Ansible config file:

 - create /etc/ansible directory if it doesn't exist.
 - create /etc/ansible/ansible.cfg if it doesn't exist and add the following four lines (substituting <key file name> with your key file):

```
[defaults]
private_key_file = <key file name>
host_key_checking = False
callback_whitelist = profile_tasks, timer
```

The last line above adds timing information to your playbook, which improves a demo - and it works for any Ansible playbook, not just AWS.

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