job [[ template "job_name" . ]] {
    datacenters = [[ .mygento_traefik.datacenters | toStringList ]]
    type = "system"

    group "traefik" {
        count = 1

        volume "certs" {
            type      = "host"
            source    = "acme_certificates"
            read_only = false
        }

        network {
            port "http" {
                static = 80
            }

            port "https" {
                static = 443
            }
        }

        task "traefik" {
            driver = "docker"
            config {
                image = "traefik:v2.9"
                ports = ["http", "https"]
                network_mode = "host"
                args = [
                    "--entrypoints.web.address=:${NOMAD_PORT_http}",
                    "--entrypoints.websecure.address=:${NOMAD_PORT_https}",
                    "--certificatesresolvers.mygentoresolver.acme.email=[[ .mygento_traefik.acme_email ]]",
                    "--certificatesresolvers.mygentoresolver.acme.storage=/acme/acme.json",
                    "--certificatesresolvers.mygentoresolver.acme.httpchallenge.entrypoint=web",
                    "--providers.nomad.exposedByDefault=false",
                    "--providers.nomad=true",
                    "--providers.nomad.endpoint.address=http://${NOMAD_HOST_IP_http}:4646",
                    "--accesslog=true"
                    # "--api.dashboard=true",
                ]
            }

            resources {
                cpu    = [[ .mygento_traefik.traefik_task_resources.cpu ]]
                memory = [[ .mygento_traefik.traefik_task_resources.memory ]]
            }

            volume_mount {
                volume      = "certs"
                destination = "/acme"
            }
        }
    }
}