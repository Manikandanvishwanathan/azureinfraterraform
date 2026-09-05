variable "users" {
  description = "Map the user"
  type = map(object({
    first_name = string
    last_name = string
    job_title = optional(string, "Employee")
    department = optional(string, "Employee")
  })) 
}