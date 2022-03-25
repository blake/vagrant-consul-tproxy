job "api2" {
  datacenters = ["dc1"]
  type = "service"

  group "api2" {
    count = 1

    network {
      mode = "bridge"
      dns {
        servers = ["172.17.0.1"]
      }

      port "api2" {
        to = 9090
      }
    }

    task "initialize-iptables" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      resources {
        memory = 50
      }

      driver = "exec"
      config {
        cap_add = ["NET_ADMIN"]
        command = "sudo"
        args = ["consul-redirect-traffic", "-proxy-inbound-port=${NOMAD_PORT_connect_proxy_api2}"]
      }
    }

    task "api2" {
      driver = "docker"

      resources {
        memory = 50
      }

      config {
        image = "nicholasjackson/fake-service:v0.23.1"
        ports = ["api2"]
      }

      env {
        NAME = "${NOMAD_JOB_NAME}"
        UPSTREAM_URIS="http://api3.virtual.consul"
        MESSAGE = "Hello from ${NOMAD_JOB_NAME}!"
      }

    }
    service {
      name = "${NOMAD_JOB_NAME}"
      port = 9090
      connect {
        sidecar_service {}

        sidecar_task {
          user = "envoy"
          resources {
            memory = 256
          }
        }
      }
    }
  }
}
