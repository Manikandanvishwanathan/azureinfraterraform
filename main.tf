terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azuread" {
  # Authenticates using Azure CLI session (az login) by default,
  # or Service Principal environment variables (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID).
}

# Fetch the primary tenant domain name dynamically (e.g., yourtenant.onmicrosoft.com)
data "azuread_domains" "default" {
  only_initial = true
}

# Generate a strong, random temporary password
resource "random_password" "user_passwords" {
  for_each = var.users
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create the Azure AD / Entra ID User
resource "azuread_user" "users" {
  for_each = var.users
  user_principal_name = "${lower(each.value.first_name)}.${lower(each.value.last_name)}@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "${each.value.first_name} ${lower(each.value.last_name)}"
  given_name          = "each.value.first_name"
  surname             = "each.value.last_name"
  mail_nickname       = "${lower(each.value.first_name)}${lower(substr(each.value.last_name, 0, 1))}"
  password            = random_password.user_passwords[each.key].result

  # Forces the user to change password upon first sign-in
  force_password_change = true

  # Optional metadata
  job_title  = each.value.job_title
  department = each.value.department
}


provider "azurerm" {
  features {}
}

# 1. Target Resource Group
data "azurerm_resource_group" "rg" {
  name = "rg-production"
}

# 2. Look up a Built-in Policy Definition (e.g., "Require a tag on resources")
data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

# 3. Assign the Policy to the Resource Group
resource "azurerm_resource_group_policy_assignment" "rg_tag_enforcement" {
  name                 = "rg-require-dept-tag"
  resource_group_id    = data.azurerm_resource_group.rg.id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  display_name         = "Enforce 'Department' Tag on Resources"
  description          = "Ensures any resource deployed into this Resource Group has a Department tag."

  # Supply parameters required by this policy definition
  parameters = jsonencode({
    "tagName" = {
      "value" = "Department1"
    }
  })
}
