source "vagrant" "ubuntu_20_04" {
  source_path = "bento/ubuntu-20.04"
  box_version = "202105.25.0"
  communicator = "ssh"
  provider = "virtualbox"

  insert_key= true
}

build {
  sources = [
    "source.vagrant.ubuntu_20_04"
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
