variable "create-az-resource-provider-names" {
  type        = bool
  description = "Specifies whether Azure Resource Providers should be Registered."
}

variable "az-resource-provider-names" {
  type        = list(string)
  description = "List of Azure Resource Providers."
}

