# Terraform and Ansible exercise

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)


## Table of Contents

- [Background](#background)
- [Content](#content)
- [Install](#install)
- [Usage](#usage)
- [Maintainers](#maintainers)
- [Improvement](#improvement)
- [License](#license)

## Background

## Content
ansible
playbook.yaml
security_agent_config_conf
security_agent_installer_linux_amd64_v1.0.0.sh 
variables.yaml

terraform
main.tf
outputs.tf
variables.tf

## Install
Install terraform cli
Install az cli

## Usage
Login into Azure and set to the correct subscription
```az login
az account show
az account set --subscription "<id>"
```
Change the working directory to the terraform directory, verify the variables.tf and make sure the resulting virtual machine is to the desired configuration, then run the following commands to execute terraform
```
terraform init
terraform apply
```
If the terraform execution is completed, it should return the following results:
```
public_ip_address = "<Output IP>"
resource_group_name = "CSGSecAgent"
tls_private_key = <sensitive>
```
Since terraform doesn't show the generated private key by default, it will needed to be exported manually to a path of your choosing and needs the correct permission for ansible to use the private key. These sample commands will export the key to the ssh directory. You may change the directory as needed. 
```
terraform output -raw tls_private_key > ~/.ssh/ansible/private_key.pem
chmod 400 ~/.ssh/ansible/private_key.pem
```
Once you have verify that the created virtual machine is running, we can move on to using ansible to installing the security agent onto the remote virtual machine.
Create the ansible host directory if it does not exist
```
mkdir /etc/ansible/hosts
```
Add entry with the IP address obtained from the terraform outputs:
Note: If you've change the directory of the private key, you will need to change it to the same directory in the entry as well.
```
\[CSGSecAgentUbuntu20\]
<Output IP> ansible_user=CSGSecAgentUser ansible_ssh_private_key_file=~/.ssh/ansible/private_key.pem
```
Change the working directory to the ansible directory
Edit the variables.yaml file to add the unique token and verify the install path for the security agent
Now execute the ansible with the playbook
```
ansible-playbook playbook.yaml
```
or for full details of the execution:
```
ansible-playbook -vvv playbook.yaml
```
If the playbook execution is successful, then ansible should've made 5 changes as indicated in the logs.

## Improvement
General: Use a key management solution to handle generated private keys for both scale and security challenges.
General: Create a python wrapper to perform provisioning of the vm and installing the security agent in a single command line
terraform: Currently only for single use, should add support for creating multple virtual machines and/or in specific resource group.
ansible: Add hosts as an configurable variable
ansible: Support for multiple script in case of different versions and configurations. Currently is hardcoded for security_agent_installer_linux_amd64_v1.0.0. and assumed no other versions exist.
ansible: Support for multiple unique tokens. The token list should be able to handle adding or removing a used token for additional automation.