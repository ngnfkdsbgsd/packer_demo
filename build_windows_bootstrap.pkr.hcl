packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.3"
      source = "github.com/hashicorp/vmware"
    }
    sshkey = {
      version = ">= 1.0.1"
      source = "github.com/ivoronin/sshkey"
    }
  }
}

data "sshkey" "install"{
}

source "vmware-iso" "windows" {
  iso_url  = "${ join("/", [path.cwd, "images", local.iso_name]) }"
  iso_checksum = "none"
  shutdown_command = "shutdown /s /t 30 /f"
  boot_command = ["<enter>"]
  boot_wait = "7s"

  vm_name = "${ var.os_type }_${ formatdate("DD_MM_YYYY_h'h'mm", timestamp()) }"
  guest_os_type = var.os_type
  disk_adapter_type = "lsisas1068"
  disk_size = var.disk_size
  disk_type_id = "0"
  cpus = var.cpus
  cores = var.cores
  memory = var.memory
  network = var.network
  vmx_data = {
    "numvcpus":var.cores * var.cpus
    "vhv.enable":"TRUE"
    "vpmc.enable":"TRUE"
    "vcpu.hotadd":"TRUE"
    "mem.hotadd":"TRUE"
    "firmware":"efi"
    "templateVM":"TRUE"
    "monitor_control.enable_softResetClearTSC":"TRUE"
  }
  snapshot_name = "starter"

  cd_files = [".\\bootstrap_scripts\\*", ".\\provision\\*"]
  cd_content = { 
    "autounattend.xml" = templatefile("${path.root}/Autounattend.pkrtpl.hcl", {svc_admin_login = var.svc_admin_login, svc_admin_password = var.svc_admin_password, default_admin_password = var.default_admin_password})
    "key_pub.pem" = data.sshkey.install.public_key
  }
  cd_label = "bootstrap"

  communicator = "ssh"
  ssh_username = var.svc_admin_login
  ssh_password = var.svc_admin_password
  ssh_file_transfer_method = "sftp"
  ssh_timeout = "3h"

  output_directory = "${ join("/", [path.cwd, var.out_dir]) }"
}

build {
  name    = "${ var.os_type }_golden_image"
  sources = ["vmware-iso.windows"]

  provisioner "powershell" {
    script = ".\\provision\\windows_update.ps1"
    elevated_user = var.svc_admin_login
    elevated_password = var.svc_admin_password
    max_retries = 7
    pause_before = "5m"
  }

  provisioner "powershell" {
    script = ".\\provision\\cleanup.ps1"
    elevated_user = var.svc_admin_login
    elevated_password = var.svc_admin_password
  }

  post-processor "shell-local" {
      inline = ["powershell -command \"Copy-Item -Path .\\packer_cache\\ssh_private_key_packer_rsa.pem -Destination .\\out\""]
  }

  post-processor "shell-local" {
      inline = ["powershell -file \".\\provision\\cleanup_vmx.ps1\""]    
  }

  post-processor "manifest" {
    output = "manifest.json"
    custom_data = {
      admin_ssh_private_key = "ssh_private_key_packer_rsa.pem"
      admin_name = var.svc_admin_login
      admin_password = var.svc_admin_password
    }
  }
}
#https://github.com/rgl/windows-vagrant/blob/master/windows-10-1809.pkr.hcl