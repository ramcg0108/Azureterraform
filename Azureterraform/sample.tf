# Configure the Azure Provider
provider "azurerm"{
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "1.32.1"
subscription_id = "aaeb58ba-f487-4492-b224-aaab325ff672"
client_id = "4bc79de4-62b5-40c6-9a23-e89b62bbc125"
client_secret = "m_qjBfXWTZeED-P2ogl5CBTs1AE?I:i7"
tenant_id = "98fdb452-426e-4115-a818-f2107c956852"
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "test-resources"
  location = "East US"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "example" {
  name                 = "testsubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefix       = "10.0.1.0/24"
}
#terraform {
 # backend "azurerm" {
 #   resource_group_name  = "test-resources"
 #  storage_account_name  = "backendstate1"
 #   container_name       = "backendstate1"
 #   key                  = "terraform.tfstate"
 # }
#}

output "subnet_id" {
  value = azurerm_subnet.example.id
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
variable "prefix" {
  default = "tfvmex"
}
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_D2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "DevVM"
  }
}