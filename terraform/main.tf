# Author: Cheuk Wong (cheuk.wong@citrix.com)
# This terraform document is for provisioning a virtual machine with SSH access.
# Cloud Provider: Azure
#
# Required input variables:
#   virtual_machine_name
#   virtual_machine_username
#   resource_group_name
#   resource_group_location
#   public_ip_type
#   os_offer
#   os_sku
#   os_version
#
# Expected output: Virtual machine with specific OS and a dynamic IP with SSH access with key based authentication

# Provides Terraform configuration details
terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

# Required by Azure even if no feature is used
provider "azurerm" {
  features {}
}

# Resource Group for the virtual machine
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
    environment = "dev"
    source      = "Terraform"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "csg_sec_agent_vn" {
  name                = format("%s%s", azurerm_resource_group.rg.name, "VirtualNetwork")
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "csg_sec_agent_subnet" {
  name                 = format("%s%s", azurerm_resource_group.rg.name, "Subnet")
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.csg_sec_agent_vn.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "csg_sec_agent_public_ip" {
  name                = format("%s%s", azurerm_resource_group.rg.name, "PublicIP")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = var.public_ip_type
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "csg_sec_agent_nsg" {
  name                = format("%s%s", azurerm_resource_group.rg.name, "SecurityGroup")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH22"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH443"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "csg_sec_agent_nic" {
  name                = format("%s%s", azurerm_resource_group.rg.name, "NIC")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "csg_sec_agent_configuration"
    subnet_id                     = azurerm_subnet.csg_sec_agent_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.csg_sec_agent_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.csg_sec_agent_nic.id
  network_security_group_id = azurerm_network_security_group.csg_sec_agent_nsg.id
}

# Create (and display) an SSH key
resource "tls_private_key" "csg_sec_agent_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "csg_sec_agent_vm" {
  name                  = format("%s%s", azurerm_resource_group.rg.name, "VM")
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.csg_sec_agent_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = format("%s%s", azurerm_resource_group.rg.name, "OsDisk")
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }

  computer_name                   = var.virtual_machine_name
  admin_username                  = var.virtual_machine_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.virtual_machine_username
    public_key = tls_private_key.csg_sec_agent_ssh_key.public_key_openssh
  }
}