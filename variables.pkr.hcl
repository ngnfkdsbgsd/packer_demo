variable "iso_fullpath" {
	type = string
	description = "Fullpath to ISO windows image"
	default = null
}

variable "disk_size" {
	type = number
	description = "VM disk size"
	default = 40000
}

variable "cores" {
	type = number
	description = "VM # of cores"
	default = 2
}

variable "cpus" {
	type = number
	description = "VM # of cpus"
	default = 1
}

variable "memory" {
	type = number
	description = "VM amount of RAM"
	default = 4096
}

variable "network" {
	type = string
	description = "VMWare Network Device"
	default = "VMnet8"
}

variable "out_dir" {
	type = string
	description = "Artifact target folder"
	default = "out"
}

variable "svc_admin_login" {
	type = string
	description = "Administration account for automation tasks"
	default = "svc_automation"
}

variable "svc_admin_password" {
	type = string
	description = "Password for account SVC_ADMIN_LOGIN"
	default = "gjpdjyb-03"#bcrypt("pleasechangeme")
}

variable "default_admin_password" {
	type = string
	description = "Password for default 'Administrator' account"
	default = "pleasechangeme"
}

variable "os_type" {
	type = string 
	description = "OS type as per VMWare enum"
	default = "windows8srv-64"
}
locals {
	iso_name = "${ var.iso_fullpath == null ? coalesce(fileset("./images", "*{iso,ISO}")...) : var.iso_fullpath }"
}

