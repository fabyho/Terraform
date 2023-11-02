# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 1.6.3"
    }
  }


}

provider "azurerm" {
  features {}
}

# Deploy Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "RG-PRD01"
  location = "eastus2"
}

# Deploy VNET
resource "azurerm_virtual_network" "VNET-Terraform" {
  name                = "VNET-Terraform"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Deploy Subnet
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet01.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Deploy NSG
resource "azurerm_network_security_group" "nsg01" {
  name                = "nsg-prd01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
  }
}

# Associar NSG Subnet
resource "azurerm_subnet_network_security_group_association" "nsg01" {
  subnet_id                 = azurerm_subnet.sub01.id
  network_security_group_id = azurerm_network_security_group.nsg01.id
}


# Deploy Public IP
resource "azurerm_public_ip" "pip01" {
  name                = "pip-vmwin01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

# Deploy NIC
resource "azurerm_network_interface" "vnic01" {
  name                = "nic-vm-win01"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip01.id
  }
}

# Deploy VM
resource "azurerm_windows_virtual_machine" "vm01" {
  name                            = "vm-win01"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B2S"
  admin_username                  = "admin.tftec"
  admin_password                  = "Tftec@2022"
  network_interface_ids = [
    azurerm_network_interface.vnic01.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

#DEPLOY VM LINUX

# Deploy VNET do Linux
resource "azurerm_virtual_network" "vnet02" {
  name                = "vnet-prd02"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["172.16.0.0/16"]
}


# Deploy Subnet do Linux
resource "azurerm_subnet" "sub02" {
  name                 = "sub-prd02"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet02.name
  address_prefixes     = ["172.16.0.0/24"]
}

# Deploy NSG do Linux
resource "azurerm_network_security_group" "nsg02" {
  name                = "nsg-prd02"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "172.16.0.0/24"
  }
}

# Associar NSG Subnet
resource "azurerm_subnet_network_security_group_association" "nsg02" {
  subnet_id                 = azurerm_subnet.sub02.id
  network_security_group_id = azurerm_network_security_group.nsg02.id
}

# Deploy Public IP Linux
resource "azurerm_public_ip" "pip02" {
  name                = "pip-vmlnx01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

# Deploy NIC VM Linux
resource "azurerm_network_interface" "vnic02" {
  name                = "nic-vm-lnx01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip02.id
  }
}


# Deploy VM Linux
resource "azurerm_linux_virtual_machine" "vm02" {
  name                            = "vm-lnx01"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B2S"
  admin_username                  = "admintftec"
  admin_password                  = "Tftec@2022"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vnic02.id,
  ]

   source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

