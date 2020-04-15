provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.0.0"
  features {}
}

resource "azurerm_resource_group" "terraform" {
  name     = "terraform"
  location = "East US"
}

resource "azurerm_virtual_network" "terraform" {
  name                = "terraform-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

resource "azurerm_subnet" "terraform" {
  name                 = "terraform"
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.terraform.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "example" {
  name                    = "terraform-pip"
  location                = azurerm_resource_group.terraform.location
  resource_group_name     = azurerm_resource_group.terraform.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

}

resource "azurerm_network_interface" "terraform" {
  name                = "terraform-nic"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "terraform_ip_configuration"
    subnet_id                     = azurerm_subnet.terraform.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_network_security_group" "terraform" {
  name                = "terraform-security-group"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

resource "azurerm_network_security_rule" "terraform" {
  name                        = "terraform-ui"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "8800"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraform.name
  network_security_group_name = azurerm_network_security_group.terraform.name
}

resource "azurerm_virtual_machine" "main" {
  name                  = "terraform-vm"
  location              = azurerm_resource_group.terraform.location
  resource_group_name   = azurerm_resource_group.terraform.name
  network_interface_ids = [azurerm_network_interface.terraform.id]
  vm_size               = "Standard_D2s_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb = "64"
  }
  os_profile {
    computer_name = "terraform"
    admin_username = "terraform"
    custom_data = file("cloud-config.tpl")
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        key_data = file("~/.ssh/id_rsa.pub")
        path = "/home/terraform/.ssh/authorized_keys"
    }
  }
}