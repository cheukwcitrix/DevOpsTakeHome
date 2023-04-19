# Terraform and Ansible exercise

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)


## Table of Contents

- [Background](#background)
- [Install](#install)
- [Usage](#usage)
- [Design](#design)
- [Improvement](#improvement)
- [License](#license)

## Background
This is a sample project with the end goal of creating an Ubuntu 20.04 virtual machine. The created virtual machine will come with an admin account using a key based authentication, and it will be provisioned in an Azure subscription of user's choice. The tool of choice for provisioning will be terraform by HashiCorp. Once the virtual machine has been provisioned, an ansible script will be used to deploy a security agent. The security agent will be installed with an unique token via a script copied from ansible node to the remote virtual machine.

## Install
Install [terraform cli](https://developer.hashicorp.com/terraform/downloads)<br/>
Install [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)<br/>
Install [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)<br/>

Note: This project was originally developed using the following software version:<br/>
Visual Studio Code 1.59.0<br/>
azure-cli 2.47.0<br/>
Terraform v1.4.5<br/>
ansible [core 2.14.4]<br/>

## Usage
Login into Azure and set to the correct subscription
```
az login
az account set --subscription "<id>"
```
Change the working directory to the terraform directory inside the project; verify the variables.tf and make sure the resulting virtual machine is to the desired configuration, then run the following commands to execute terraform
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
Once you have verified that the created virtual machine is running, we can move on to using ansible to installing the security agent onto the remote virtual machine.<br/>
Create the ansible host directory if it does not exist<br/>
```
mkdir /etc/ansible/hosts
```
Add entry with the IP address obtained from the terraform outputs from previous step:<br/>
Note: If you've change the directory of the private key, you will need to change the value of "ansible_ssh_private_key_file" to the same directory in the entry as well.<br/>
```
[CSGSecAgentUbuntu20]
<Output IP> ansible_user=CSGSecAgentUser ansible_ssh_private_key_file=~/.ssh/ansible/private_key.pem
```
Change the working directory to the ansible directory in the project<br/>
Edit the variables.yaml file to add the unique token and verify the install path for the security agent<br/>
Now execute the ansible with the playbook<br/>
```
ansible-playbook playbook.yaml
```
or for full details of the execution:
```
ansible-playbook -vvv playbook.yaml
```
If the playbook execution is successful, then ansible should've made 5 changes as indicated in the logs.

## Design
Terraform: While the terraform plan is for single use, most of the important fields such as machine name, os version, and username are set by variables. With some simple modification, the plan can be made to provision multiple virtual machines. The priority of the SSH over HTTPS is given slightly over HTTP since the secure communication might be more important.

Ansible: Install path is set as a variable in case we might need to install the agent in different paths. The token is set as a variable so it is not hardcoded into the playbook and can be changed as needed. Rather than writing the install script's config file directly to the remote virtual machine via ansible, it is copied from the ansible node to the remote virtual machine in case we need to change the configuration file without changing the ansible playbook.

## Improvement
General: Use a key management solution to handle generated private keys for both scale and security challenges.<br/>
General: Create a python wrapper to perform provisioning of the vm and installing the security agent in a single command line<br/>
terraform: Currently only for single use, should add support for creating multple virtual machines and/or in specific resource group.<br/>
ansible: Add hosts as an configurable variable<br/>
ansible: Support for multiple install script in case of different versions and configurations. Currently is hardcoded for security_agent_installer_linux_amd64_v1.0.0. and assumed no other versions exist.<br/>
ansible: Support for multiple unique tokens. The token list should be able to handle adding or removing a used token for additional automation.<br/>

## License
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)