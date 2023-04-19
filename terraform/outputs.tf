output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.csg_sec_agent_vm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.csg_sec_agent_ssh_key.private_key_pem
  sensitive = true
}