# Vagrant box with prebuilt components

## Description

This Vagrantfile deploys a multi-machine environment consisting of three nodes.
Consul, Envoy, and the required transparent proxy configurations have been
pre-installed into the image.

### Environment details

|Machine Name|Description|IP|Guest Port|Host Port|
|----|----|----|----|---|
|consul-server|Consul server agent|192.0.2.254|8500|8500|
|web|Consul client running "fake-service" service|192.0.2.10|9090|9090|
|api1|Consul client running "fake-service" service|192.0.2.20|9090|n\a|
|api2|Consul client running "fake-service" service|192.0.2.21|9090|n\a|
|api3|Consul client running "fake-service" service|192.0.2.22|9090|n\a|

For each client, Vagrant configures the advertised service name and port in
Consul by by placing a JSON file at `/srv/consul/service-config.json` with the following syntax.

```json
{
  "annotations": {
    "consul.hashicorp.com/connect-service": "api",
    "consul.hashicorp.com/connect-service-port": "9090",
    "consul.hashicorp.com/transparent-proxy": true
  }
}
```

This file is read by one of the initialization scripts at VM boot, which uses
it to generate the final service registration file
(`/etc/consul.d/service-registration.json`) for Consul.

The annotation `consul.hashicorp.com/connect-service` is required. All other
supported annotations are optional.

#### Supported annotations

##### Official annotations

For full descriptions and examples of using each annotation, see
<https://www.consul.io/docs/k8s/connect#available-annotations>.

* `consul.hashicorp.com/connect-service`
* `consul.hashicorp.com/connect-service-port`
* `consul.hashicorp.com/connect-service-upstreams`
* `consul.hashicorp.com/service-meta-<x>`
* `consul.hashicorp.com/service-tags`
* `consul.hashicorp.com/transparent-proxy`
* `consul.hashicorp.com/transparent-proxy-exclude-inbound-ports`
* `consul.hashicorp.com/transparent-proxy-exclude-outbound-cidrs`
* `consul.hashicorp.com/transparent-proxy-exclude-outbound-ports`
* `consul.hashicorp.com/transparent-proxy-exclude-uids`

##### Custom annotations

Custom annotations are also supported which provide additional functionality
that is not implemented officially in Consul. These annotations are tagged with
the `alpha` prefix as they are considered unstable, and subject to change/removal.

* `alpha.consul.hashicorp.com/virtual-ip`: Configures a `virtual` tagged address on the sidecar service.

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

### Web UI

Vagrant is configured with a port forwarding rule to expose the Web server
UI on <http://localhost:9090>.
