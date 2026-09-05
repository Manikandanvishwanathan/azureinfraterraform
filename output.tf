output "created_users" {
  description = "Map of created users, their UPNs, and their temporary passwords."
  value = {
    for k, u in azuread_user.users : k => {
      upn                = u.user_principal_name
      temporary_password = random_password.user_passwords[k].result
    }
  }
  sensitive = true
}