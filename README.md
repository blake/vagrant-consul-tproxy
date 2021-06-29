# Consul service mesh transparent proxy on virtual machines

This repo contains example Vagrant environments for deploying Consul service
mesh across multiple virtual machines with
[transparent proxy]
enabled for service-to-service communication.

[transparent proxy]: https://www.consul.io/docs/connect/transparent-proxy

## Test environments

Each environment deploys a set of three servers. One of the servers acts as a
Consul server. The other two servers run Consul client agents, as well as [Envoy]
sidecar proxies for the deployed applications.

[Envoy]: https://www.envoyproxy.io/

```text
            _________________
            | Consul server |
            -----------------
               /          \
              /            \
             /              \
|----------------|      |----------------|
| client agent   |      | client agent   |
| _____  _______ |      | _______  _____ |
| |app|->|proxy|-|------|>|proxy|->|app| |
| -----  ------- |      | -------  ----- |
|----------------|      |----------------|
```

The various environments are meant to highlight the different methods which can
be used by operators to deploy Consul service mesh alongside their application
services. Some operators may prefer to install and configure all service at
deployment time, while others may prefer to utilize a base image containing a
standard set of components, and customize it slightly at deployment time for
the contained application.

* [examples/vagrant/cloud-init-injection](examples/vagrant/cloud-init-injection) -
  Installs and configures Consul, Envoy, and the applications using cloud-init.
* [examples/vagrant/prebuilt-image](examples/vagrant/prebuilt-image) - Uses a
  prebuilt image which contains Consul and Envoy. The applications are installed
  using shell scripts provided via cloud-init.

## Sidecar initialization architecture

After Consul and Envoy are installed into the environment, additional steps are
needed to optionally bring the deployed application into the service mesh.
Broadly this translates into the following:

1. Register the service with Consul.
2. Install the iptables rules which handle traffic redirection for the
   application.
3. Start the service's Envoy sidecar proxy.

The test environments contain the following scripts and systemd services which
work together to provide a simple way to add an application to the service mesh through an opinionated bootstrapping/configuration process that closely resembles
the [sidecar injection] model supported by Consul on Kubernetes.

[sidecar injection]: https://www.consul.io/docs/k8s/connect#installation-and-configuration

```text
/etc/systemd/system
├── consul-sidecar-init.service
├── envoy@.service
/srv/consul
├── generate-sidecar-configs.py
/usr/local/bin
├── consul-cleanup-iptables
├── consul-redirect-traffic
```

The general provisioning flow is as follows:

1. When the server starts, `consul-sidecar-init.service` runs and checks for the
   existence of `/srv/consul/service-config.json`. This file can be pre-baked into
   the image, or installed at deploy time using cloud-init, Ansible, etc. The file
   contains information about the deployed service such as its name, listening
   port, etc. If this file exists, the service executes `generate-sidecar-configs.py`.
1. `generate-sidecar-configs` reads the service configuration file and uses the
   information to generate a Consul service registration file for the application
   which contains the necessary [sidecar service registration] stanza to add the
   service to the mesh.
     1. The generated file is saved at `/etc/consul.d/service-registration.json`.
     1. The script calls systemd to enable and start an Envoy proxy for the
        application process (i.e., `systemctl start envoy@app`).
1. When the systemd unit is started, it executes two commands;
   `consul-redirect-traffic` to install the iptables redirection rules – if the
   proxy is configured to operate in `transparent` mode – and `consul connect envoy`
   to start the Envoy process. When the unit is stopped, the Envoy process is
   terminated and the unit executes `consul-cleanup-iptables` to remove the
   iptables redirection rules.

[sidecar service registration]: https://www.consul.io/docs/connect/registration/sidecar-service
