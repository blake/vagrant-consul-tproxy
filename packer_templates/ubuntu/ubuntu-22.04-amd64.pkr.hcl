# This variable can be set in the environment by running the following command,
# assuming you have already authenticated to Vagrant Cloud using
# `vagrant cloud auth`.
#
# export VAGRANT_CLOUD_TOKEN=$(cat ~/.vagrant.d/data/vagrant_login_token)

# Vagrant Box version
locals {
  vagrant_cloud_user = "blakec"
  version = "0.0.1"
}

source "vagrant" "ubuntu_22_04" {
  source_path = "ubuntu/jammy64"
  box_version = "v20220204.0.0"
  communicator = "ssh"
  provider = "virtualbox"

  insert_key= true
}

build {
  sources = [
    "source.vagrant.ubuntu_22_04"
  ]

  provisioner "ansible" {
    playbook_file = "../playbook.yaml"
    galaxy_file = "../galaxy.yaml"
  }

  provisioner "shell" {
    # Remove Ansible-related files left over after provisioning
    inline = ["rm --recursive --force $HOME/\\~*"]
  }

  post-processor "manifest" {}

  post-processor "checksum" {
    checksum_types = ["sha256"]
  }

  post-processor "vagrant-cloud" {
    only = ["vagrant.ubuntu_22_04"]

    box_tag = "${local.vagrant_cloud_user}/ubuntu-22.04-consul-transparent-proxy"
    version = "${local.version}"
  }
}
