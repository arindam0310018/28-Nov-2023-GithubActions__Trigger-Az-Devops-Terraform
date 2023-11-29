#####################################
## Resource Provider Registration:-
#####################################

resource "azurerm_resource_provider_registration" "az-resource-provider-register" {
  count   = var.create-az-resource-provider-names == true ? length(var.az-resource-provider-names) : 0
  name    = var.az-resource-provider-names[count.index]
}



