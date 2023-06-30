job [[ template "job_name" . ]] {
    datacenters = [[ .mygento_traefik.datacenters | toStringList ]]
    [[- if eq .mygento_traefik.job_type "system" ]]
    type = "[[ .mygento_traefik.job_type ]]"
    [[- end ]]

    group "traefik" {
        count = 1

        [[- if eq .mygento_traefik.job_type "proxy" ]]
        network {
            port "http" {
                to = 80
                host_network = "private"
            }
        }

        [[ if .mygento_traefik.node_class ]]
        constraint {
            attribute = "${node.class}"
            value     = [[ .mygento_traefik.node_class | quote ]]
        }
        [[- end ]]
        [[- end ]]

        [[- if eq .mygento_traefik.job_type "system" ]]
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
                image = "traefik:v2.10"
                ports = ["http", "https"]
                network_mode = "host"
                args = [
                    "--entrypoints.web.address=:${NOMAD_PORT_http}",
                    "--entrypoints.websecure.address=:${NOMAD_PORT_https}",
                    "--certificatesresolvers.mygentoresolver.acme.email=[[ .mygento_traefik.acme_email ]]",
                    "--certificatesresolvers.mygentoresolver.acme.storage=/acme/acme.json",
                    "--certificatesresolvers.mygentoresolver.acme.httpchallenge.entrypoint=web",
                    "--providers.nomad=true",
                    "--providers.nomad.exposedByDefault=false",
                    "--providers.nomad.endpoint.address=http://${NOMAD_HOST_IP_http}:4646",
                    "--providers.file.directory=/etc/traefik/dynamic",
                    "--accesslog=true"
                    # "--api.dashboard=true",
                ]

                mount {
                    type   = "bind"
                    source = "local/dynamic"
                    target = "/etc/traefik/dynamic"
                }
            }

            resources {
                cpu    = [[ .mygento_traefik.traefik_task_resources.cpu ]]
                memory = [[ .mygento_traefik.traefik_task_resources.memory ]]
            }

            volume_mount {
                volume      = "certs"
                destination = "/acme"
            }

            template {
                data = <<EOH
tls:
  options:
    default:
      minVersion: VersionTLS12
      sniStrict: true
      cipherSuites:
        # Recommended ciphers for TLSv1.2
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
        # Recommended ciphers for TLSv1.3
        - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
      curvePreferences:
        - secp521r1
        - secp384r1
    modern:
      minVersion: VersionTLS13
EOH
                destination     = "local/dynamic/tls.yml"
            }
        }
        [[- end ]]

        [[- if eq .mygento_traefik.job_type "proxy" ]]
        task [[ .mygento_traefik.job_name | quote ]] {
            driver = "docker"
            config {
                image = "traefik:v2.10"
                ports = ["http"]

                mount {
                    type   = "bind"
                    source = "local/config"
                    target = "/etc/traefik"
                }
            }

            service {
                name = [[ .mygento_traefik.job_name | quote ]]
                port = "http"
                provider = "nomad"
                tags = [
                    "traefik.enable=true",
                    "traefik.http.routers.[[ .mygento_traefik.job_name ]].rule=[[ .mygento_traefik.proxy_from ]]",
                    "traefik.http.routers.[[ .mygento_traefik.job_name ]].tls=true",
                    "traefik.http.routers.[[ .mygento_traefik.job_name ]].tls.certresolver=mygentoresolver",
                ]
            }

            template {
                data = <<EOH
accessLog: {}
providers:
    file:
        filename: /etc/traefik/dynamic.yml
entryPoints:
    web:
        address: ":80"
        forwardedHeaders:
            trustedIPs:
                - "127.0.0.1/32"
                - "{{ env "NOMAD_IP_http" }}"
EOH
                destination     = "local/config/traefik.yml"
            }

            template {
                data = <<EOH
http:
    routers:
        proxyrouter:
            rule: "[[ .mygento_traefik.proxy_from ]]"
            service: proxy-service
    services:
        proxy-service:
            loadBalancer:
                servers:
                    - url: "http://[[ .mygento_traefik.proxy_to ]]"
EOH
                destination     = "local/config/dynamic.yml"
            }

            resources {
                cpu    = [[ .mygento_traefik.traefik_task_resources.cpu ]]
                memory = [[ .mygento_traefik.traefik_task_resources.memory ]]
            }
        }
        [[- end ]]
    }
}
