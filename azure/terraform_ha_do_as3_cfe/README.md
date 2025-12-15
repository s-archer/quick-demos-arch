To apply terraform, reference separate credentials file:

terraform apply -var-file=../../../creds/azure_creds.tfvars 

The creds.tfvars file must contain four variables defined like this :

subscription_id = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
client_secret   = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
client_id       = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
tenant_id       = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"



In order to populate these variables, you need to configure API access to your Azure account:

 - within the Azure Active Directory create a new 'App' on the 'App Registration' page.
 - within the new 'App' you just created, create a new Client Secret.  The value must be saved, as you cannot retrieve it again:  
   - this value is your "${client_secret}".
 - the 'App' overview page will provide:
   - the 'Application (client) ID' is your ${client_id}"
   - the 'Directory (tenant) ID' is your ${tenant_id}"
 - 'Expose an API' by adding a 'Scope' and a 'Client Application', with the latter referencing your 'Application (client) ID'.
 - if you type 'subscriptions' into the search box at the top of the Azure Portal, you can find your Subscription ID:
  - the 'Subscription ID' is your ${subscription_id}"
- within your subscription, go to 'Access Control (IAM)' and 'Role Assignments'.  Add a Role Assignment and give your 'App' the 'Contributor Role'. 

