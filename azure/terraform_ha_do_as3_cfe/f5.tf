resource "azurerm_network_interface" "mgmt_nic" {
  count               = 2
  name                = "${var.prefix}-mgmt-nic-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}-mgmt-ip-${count.index}"
    subnet_id                     = data.azurerm_subnet.mgmt.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmt_public_ip[count.index].id
  }
  tags = {
    Name   = "${var.prefix}-mgmt-nic-${count.index}"
    source = "terraform"
  }
}


resource "azurerm_public_ip" "mgmt_public_ip" {
  count               = 2
  name                = "${var.prefix}-mgmt-pip-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = format("%s-mgmt-%s", var.prefix, count.index)
  allocation_method   = "Static"   
  sku                 = "Standard" 
  zones               = var.availabilityZones
  tags = {
    Name   = "${var.prefix}-mgmt-pip-${count.index}"
    source = "terraform"
  }
}


resource "azurerm_network_interface" "ext_nic" {
  count                = 2
  name                 = "${var.prefix}-ext-nic-${count.index}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.prefix}-ext-ip-${count.index}"
    subnet_id                     = data.azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ext_public_ip[count.index].id
  }
  tags = {
    Name   = "${var.prefix}-ext-nic-${count.index}"
    source = "terraform"
  }
}

resource "azurerm_public_ip" "ext_public_ip" {
  count               = 2
  name                = "${var.prefix}-ext-pip-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = format("%s-ext-%s", var.prefix, count.index)
  allocation_method   = "Static"   
  sku                 = "Standard" 
  zones               = var.availabilityZones
  tags = {
    Name   = "${var.prefix}-ext-pip-${count.index}"
    source = "terraform"
  }
}


resource "azurerm_network_interface" "int_nic" {
  count                = 2
  name                 = "${var.prefix}-int-nic-${count.index}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${var.prefix}-int-ip-${count.index}"
    subnet_id                     = data.azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Name   = "${var.prefix}-int-nic-${count.index}"
    source = "terraform"
  }
}

data "template_file" "do" {
  template = file("./templates/do.tpl")
}

data "template_file" "as3" {
  template = file("./templates/as3.tpl")
}

data "template_file" "cfe" {
  template = file("./templates/cfe.tpl")
}

data "template_file" "f5_init" {
  template = file("./templates/user_data_json.tpl")
  count    = 2
  vars = {
    hostname         = "${var.hostname-f5}-${count.index}.f5demo.com",
    admin_pass       = random_string.password.result,
    external_ip      = "${azurerm_network_interface.ext_nic[count.index].private_ip_addresses[0]}/24",
    internal_ip      = "${azurerm_network_interface.int_nic[count.index].private_ip_address}/24",
    internal_gw      = cidrhost(data.azurerm_subnet.internal.address_prefixes[0], 1),
    mgmt_gw          = cidrhost(data.azurerm_subnet.mgmt.address_prefixes[0], 1),
    vs1_ip           = "10.99.0.1",
    bigip1           = azurerm_network_interface.int_nic[0].private_ip_address,
    bigip2           = azurerm_network_interface.int_nic[1].private_ip_address,
    do_declaration   = data.template_file.do.rendered,
    as3_declaration  = data.template_file.as3.rendered,
    resource_group   = azurerm_resource_group.rg.name,
    subscription_id  = var.subscription_id,
    directory_id     = var.tenant_id,
    application_id   = var.client_id,
    api_access_key   = var.client_secret
  }
}

resource "local_file" "test_user_data_debug" {
  count       = 2
  content     = templatefile("./templates/user_data_json.tpl", {
    hostname         = "${var.hostname-f5}-${count.index}.f5demo.com",
    admin_pass       = random_string.password.result,
    external_ip      = "${azurerm_network_interface.ext_nic[count.index].private_ip_addresses[0]}/24",
    internal_ip      = "${azurerm_network_interface.int_nic[count.index].private_ip_address}/24",
    internal_gw      = cidrhost(data.azurerm_subnet.external.address_prefixes[0], 1),
    mgmt_gw          = cidrhost(data.azurerm_subnet.mgmt.address_prefixes[0], 1),
    vs1_ip           = "10.99.0.1",
    bigip1           = azurerm_network_interface.int_nic[0].private_ip_address,
    bigip2           = azurerm_network_interface.int_nic[1].private_ip_address,
    do_declaration   = data.template_file.do.rendered,
    as3_declaration  = data.template_file.as3.rendered,
    resource_group   = azurerm_resource_group.rg.name,
    subscription_id  = var.subscription_id,
    directory_id     = var.tenant_id,
    application_id   = var.client_id,
    api_access_key   = var.client_secret
  })
  filename = "${path.module}/user_data_debug_${count.index}.json"
}

resource "azurerm_network_interface_security_group_association" "mgmt_security" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.mgmt_nic[count.index].id
  network_security_group_id = module.mgmt-network-security-group.network_security_group_id
}

resource "azurerm_network_interface_security_group_association" "ext_security" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.ext_nic[count.index].id
  network_security_group_id = module.external-network-security-group-public.network_security_group_id
}

resource "azurerm_network_interface_security_group_association" "int_security" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.int_nic[count.index].id
  network_security_group_id = module.internal-network-security-group.network_security_group_id
}


# Create F5 BIGIP1
resource "azurerm_virtual_machine" "f5vm" {
  count                        = 2
  name                         = "${var.prefix}-bigip-${count.index}"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  primary_network_interface_id = azurerm_network_interface.mgmt_nic[count.index].id
  network_interface_ids        = [azurerm_network_interface.mgmt_nic[count.index].id, azurerm_network_interface.ext_nic[count.index].id, azurerm_network_interface.int_nic[count.index].id] 
  vm_size                      = var.f5_instance_type

  # Uncomment these lines to delete the disks automatically when deleting the VM
  delete_os_disk_on_termination     = true
  delete_data_disks_on_termination  = true
  identity {
    type = "SystemAssigned"
  }
  storage_image_reference {
    publisher = "f5-networks"
    offer     = var.f5_product_name
    sku       = var.f5_image_name
    version   = var.f5_version
  }
  storage_os_disk {
    name              = "${var.prefix}-bigip-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.storage_account_type
  }
  os_profile {
    computer_name  = "${var.prefix}-bigip-${count.index}"
    admin_username = var.f5_username
    admin_password = random_string.password.result
    custom_data    = base64encode(data.template_file.f5_init[count.index].rendered)
    #custom_data    = data.template_file.f5_init[count.index].rendered
    
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  plan {
    name      = var.f5_image_name
    publisher = "f5-networks"
    product   = var.f5_product_name
  }
  zones = var.availabilityZones
  tags = {
    Name   = "${var.prefix}-bigip-[count.index]"
    source = "terraform"
  }
  depends_on = [azurerm_network_interface_security_group_association.mgmt_security, azurerm_network_interface_security_group_association.int_security, azurerm_network_interface_security_group_association.ext_security]
}

resource "azurerm_virtual_machine_extension" "vmext0" {
  count                 = 2
  name                  = "${var.prefix}-vmext0"
  virtual_machine_id    = azurerm_virtual_machine.f5vm[count.index].id
  publisher             = "Microsoft.Azure.Extensions"
  type                  = "CustomScript"
  type_handler_version  = "2.0"
  protected_settings    = <<PROT
    {
      "script": "${base64encode(data.template_file.f5_init[count.index].rendered)}"
    }
  PROT
}

# resource "azurerm_virtual_machine_extension" "vmext1" {

#   name                  = "${var.prefix}-vmext1"
#   virtual_machine_id    = azurerm_virtual_machine.f5vm[1].id
#   publisher             = "Microsoft.Azure.Extensions"
#   type                  = "CustomScript"
#   type_handler_version  = "2.0"
#   protected_settings    = <<PROT
#     {
#       "script": "${base64encode(data.template_file.f5_init[1].rendered)}"
#     }
#   PROT
# }

