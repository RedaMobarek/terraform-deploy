# Configure Azure provider in SANDBOX subscription

provider azurerm {
    subscription_id     = "be811814-6f67-4dc5-88c0-52158ef178aa"
    client_id           = "4b04e559-24fb-4dd0-a68b-8df038ffcd39"
    client_secret       = "5lBK+CS2Yyws1ugLxBE/PlQc/xNe2f0LWxjq8bO6b6Y="
    tenant_id           = "bddddbb1-db54-40d5-b230-0609bcef2068"
}

data "azurerm_resource_group" "customimage" {
    name = "PACKER-RG"
}

data "azurerm_image" "customimage" {
    name                = "win2016iis"
    resource_group_name = "${data.azurerm_resource_group.customimage.name}" 
}

resource "azurerm_resource_group" "terraformrg" {
    name        = "TERRAFORM-RG"
    location    = "westeurope"
}

resource "azurerm_virtual_network" "terraformvnet" {
    name                    = "terraform-vnet"
    resource_group_name     = "${azurerm_resource_group.tarraformrg.name}"
    location                = "${azurerm_resource_group.terraformrg.location}"
    address_space           = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "frontend" {
    name                    = "frontend"
    resource_group_name     = "${azurerm_resource_group.tarraformrg.name}"
    location                = "${azurerm_resource_group.terraformrg.location}"
    address_prefix          = "10.1.0.0/28"
}

resource "azurerm_public_ip" "frontpip" {
    name                            = "frontgwpip"
    resource_group_name             = "${azurerm_resource_group.tarraformrg.name}"
    location                        = "${azurerm_resource_group.terraformrg.location}"
    public_ip_address_allocation    = "static"
}

resource "azurerm_lb" "frontlb" {
    name                    = "frontlb"
    resource_group_name     = "${azurerm_resource_group.tarraformrg.name}"
    location                = "${azurerm_resource_group.terraformrg.location}"

    frontend_ip_configuration {
        name                    = "frontendpip"
        public_ip_address_id    = "${azurerm_public_ip.frontpip.id}"
    }
}

resource "azurerm_lb_backend_address_pool" "backendlb" {
    name                        = "backendpool"
    resource_group_name         = "${azurerm_resource_group.tarraformrg.name}"
    loadbalancer_id             = "${azurerm_lb.frontlb.id}"
}

resource "azurerm_lb_rule" "rullb" {
    name                            = "lbhhtprule"
    resource_group_name             = "${azurerm_resource_group.tarraformrg.name}"
    loadbalancer_id                 = "${azurerm_lb.frontlb.id}"
    protocol                        = "http"
    frontend_port                   = 80
    backend_port                    = 80
    frontend_ip_configuration_name  = "frontendpip"
}

resource "azurerm_network_interface" "terraformnic" {
    name                    = "front1nic"
    resource_group_name     = "${azurerm_resource_group.tarraformrg.name}"
    location                = "${azurerm_resource_group.terraformrg.location}"

    ip_configuration {
        name                          = "front1ipconfig"
        subnet_id                     = "${azurerm_subnet.frontend.id}"
        private_ip_address_allocation = "dynamic"
    }
}

resource "azurerm_availability_set" "frontas" {
    name                               = "frontavailabilityset"
    resource_group_name                = "${azurerm_resource_group.tarraformrg.name}"
    location                           = "${azurerm_resource_group.terraformrg.location}"
    platform_fault_domain_count        = 3
}



resource "azurerm_virtual_machine" "frontendvm" {
    name                    = "frontend1"
    resource_group_name     = "${azurerm_resource_group.tarraformrg.name}"
    location                = "${azurerm_resource_group.terraformrg.location}"
    network_interface_ids   = ["${azurerm_network_interface.front1nic.id}"]
    availability_set_id     = "${azurerm_availability_set.frontas.id}"
    vm_size                 = "Standard_DS2_v2"
    
    storage_image_reference {
        id                  = "${data.azurerm_image.customimage.id}"
    }

    storage_os_disk {
        name                = "frontend1osdisk"
        caching             = "ReadWrite"
        creatae_option      = "FromImage"
        managed_disk_type   = "Standard_LRS"
    }

    os_profile {
        computer_name       = "frontend1"
        admin_username      = "admin-terraform"
        admin_password      = "@Zure2018$"
    }
}