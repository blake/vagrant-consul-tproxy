# Packer templates

Here you will find a collection of Packer templates for building Vagrant boxes
which contain the necessary dependencies for bootstrapping a VM into Consul
service mesh, and optionally configure that VM to operate in transparent proxy
mode.

## Requirements

- [Ansible](https://www.ansible.com/)
- [Packer](https://www.packer.io/)
- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)

### Using Public Boxes

Adding a prebuilt box to Vagrant.

```shell
vagrant box add blakec/ubuntu-20.04-consul-transparent-proxy
```

Using a prebuilt box in a Vagrantfile.

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "blakec/ubuntu-20.04-consul-transparent-proxy"
end

```

## Using `packer`

To build an Ubuntu 20.04 box for the VirtualBox provider.

```shell
cd ubuntu
packer build ubuntu-20.04-amd64.pkr.hcl
```

The box will be output to a folder in the current directory. You can import the box with the following commands.

```shell
mkdir output2
cp package.box ./output2
vagrant box add new-box name-of-the-packer-box.box
vagrant init new-box
vagrant up
```

See [Packer.io: Vagrant Builder - Regarding output directory and new box](https://www.packer.io/docs/builders/vagrant#regarding-output-directory-and-new-box) for more info.
