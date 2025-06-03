variable "pm_api_url" {}
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}

variable "lxc_hostname" {
  default = "lxc-demo"
}
variable "lxc_template" {
  default = "local:vztmpl/alpine-3.19-default_20240207_amd64.tar.xz"
}
