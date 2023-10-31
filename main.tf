provider "azurerm" {
  features {}
  client_id       = "4f166274-0b30-4099-bdc5-888ad48ed4b7"
  client_secret   = "AjN8Q~6zmjtEwcShjYKB9UutS9w5JauA9okDcdlT"
  subscription_id = "9baaa753-911f-4192-a73e-e9ed9fc6ef4b"
  tenant_id       = "13b96fd0-9063-418d-8c91-8f106307639f"
}
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
#   storage_data_disk {
#     name              = azurerm_managed_disk.data_disk.name
#     managed_disk_id   = azurerm_managed_disk.data_disk.id
#     create_option     = "Attach"
#     lun               = 0
#   }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
 
resource "azurerm_managed_disk" "data_disk" {
  name                 = "example-data-disk"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  storage_account_type = "Standard_LRS"
  create_option        = "Attach"  # You can also use "Attach" if you have an existing VHD
  disk_size_gb         = 100  # Adjust the size as needed
}
resource "azurerm_virtual_machine_data_disk_attachment" "example_data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.example.id
  lun                = 0  # Logical Unit Number (LUN), typically set to 0 for the first data disk
  caching            = "ReadWrite"
}
#NSG
resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
#NSG Rule
resource "azurerm_network_security_rule" "example-nsg-rule" {
  name                        = "example-nsg-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"  # Adjust for your specific needs (RDP)
  source_address_prefix       = "*"    # You may want to limit this to a specific IP or range
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name  = azurerm_network_security_group.example.name
}
#NSG Associated with Subnet
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}
