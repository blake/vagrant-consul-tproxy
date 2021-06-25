# Vagrant box with cloud-init installation

## Description

This Vagrantfile deploys a multi-machine environment consisting of three nodes.
Consul, Envoy, and the required transparent proxy configurations are installed
using a combination of cloud-init, and supporting shell scripts.

### Environment details

|Machine Name|Description|IP|Guest Port|Host Port|
|----|----|----|----|---|
|consul-server|Consul server agent|192.0.2.254|8500|8500|
|dashboard|Consul client running "dashboard" service|192.0.2.10|80|n\a|
|counting|Consul client running "counting" service|192.0.2.20|80|n\a|

For each client, the advertised service name and port are configured in Consul
by placing a JSON file at `/srv/consul/service-config.json` with the following
syntax.

```json
{
  "name": "<service name>",
  "port": <service_port>
}
```

This file is read by one of the initialization scripts installed by cloud-init,
which uses it to generate the final service registration file (`/etc/consul.d/service-registration.json`) for Consul.

## Starting the environment

The environment can be started by running the following command.

```shell
VAGRANT_EXPERIMENTAL="cloud_init,disks" vagrant up
```

## Accessing the environment

### SSH access

The machines in this environment can be accessed using `vagrant ssh`. For example:

```shell
vagrant ssh <machine name>
```

### Consul UI

Vagrant is configured with a port forwarding rule to expose the Consul server
UI on <http://localhost:8500>.

### Dashboard UI

A little extra work is needed to access the UI of the dashboard service. This is
because the iptables rules that are installed by Consul within the VM do not
permit direct access to any of the services running on the host, with the
exception of SSH which is a hardcoded exemption.

1. To access the dashboard UI, run the following command to obtain the OpenSSH
configuration required for connecting to the machine.

    ```shell
    vagrant ssh-config dashboard > dashboard-ssh-config
    ```

1. Next, use `ssh` to bind a local listener on port 8080 which forwards connections
through the `dashboard` host to the specified destination of `localhost:80`,
which is the address where the `dashboard` service is listening.

    ```shell
    ssh -NF dashboard-ssh-config -L 8080:localhost:80 dashboard
    ```

    *Note: This command only instructs SSH to forward ports, not initiate a login
    session. The terminal will appear stuck, but forwarding is working.*

1. Access the dashboard UI at <http://localhost:8080>.
