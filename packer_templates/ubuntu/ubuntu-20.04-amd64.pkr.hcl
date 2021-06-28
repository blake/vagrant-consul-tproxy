source "vagrant" "ubuntu_20_04" {
  source_path = "ubuntu/focal64"
  box_version = "20210622.0.0"
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
