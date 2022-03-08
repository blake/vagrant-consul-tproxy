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

  post-processor "checksum" {
    checksum_types = ["sha256"]
  }
  post-processor "manifest" {}
}
