terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "lab" {
  name     = "pentesting-lab-rg"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "lab" {
  name                = "lab-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "lab" {
  name                 = "lab-subnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Domain Controller NIC
resource "azurerm_network_interface" "dc" {
  name                = "dc-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.dc.id
  }
}

resource "azurerm_public_ip" "dc" {
  name                = "dc-public-ip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
}

# Domain Controller VM
resource "azurerm_windows_virtual_machine" "dc" {
  name                = "DC01"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  size                = "Standard_B2s"
  admin_username      = "labadmin"
  admin_password      = "P@ssw0rd123!ChangeMe"
  network_interface_ids = [
    azurerm_network_interface.dc.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# Attacker VM NIC
resource "azurerm_network_interface" "attacker" {
  name                = "attacker-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.attacker.id
  }
}

resource "azurerm_public_ip" "attacker" {
  name                = "attacker-public-ip"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
}



# NSG for DC
resource "azurerm_network_security_group" "dc" {
  name                = "dc-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_network_interface_security_group_association" "dc" {
  network_interface_id      = azurerm_network_interface.dc.id
  network_security_group_id = azurerm_network_security_group.dc.id
}

# NSG for Attacker
resource "azurerm_network_security_group" "attacker" {
  name                = "attacker-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

# Attacker VM (Ubuntu)
resource "azurerm_linux_virtual_machine" "attacker" {
  name                            = "attacker01"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  size                            = "Standard_B2s"
  admin_username                  = "kali"
  admin_password                  = "P@ssw0rd123!ChangeMe"
  disable_password_authentication = false
  
  network_interface_ids = [
    azurerm_network_interface.attacker.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
resource "azurerm_network_interface_security_group_association" "attacker" {
  network_interface_id      = azurerm_network_interface.attacker.id
  network_security_group_id = azurerm_network_security_group.attacker.id
}

# Outputs
output "dc_public_ip" {
  value = azurerm_public_ip.dc.ip_address
  description = "Public IP of Domain Controller"
}

output "attacker_public_ip" {
  value = azurerm_public_ip.attacker.ip_address
  description = "Public IP of Attacker Machine"
}

output "connection_info" {
  value = <<-EOT
    
    Domain Controller:
      RDP: ${azurerm_public_ip.dc.ip_address}
      Username: labadmin
      Password: P@ssw0rd123!ChangeMe
    
    Attacker Machine:
      SSH: ssh kali@${azurerm_public_ip.attacker.ip_address}
      Password: P@ssw0rd123!ChangeMe
  EOT
  description = "Connection information"
}
