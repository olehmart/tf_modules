variable "project_id" {
  type = string
}
variable "tf_service_account" {
  type = string
}
variable "config_file" {
  type = string
}
variable "sleep_after_sa_creation" {
  type = string
  default = "10s"
}
