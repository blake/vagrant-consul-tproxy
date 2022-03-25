job "api3" {
  datacenters = ["dc1"]
  type = "service"

  group "api3" {
    count = 1

    network {
      mode = "bridge"
      dns {
        servers = ["172.17.0.1"]
      }

      port "api3" {
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
        args = ["consul-redirect-traffic", "-proxy-inbound-port=${NOMAD_PORT_connect_proxy_api3}"]
      }
    }

    task "api3" {
      driver = "docker"

      resources {
        memory = 50
      }

      config {
        image = "nicholasjackson/fake-service:v0.23.1"
        ports = ["api3"]
      }

      env {
        NAME = "${NOMAD_JOB_NAME}"
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
