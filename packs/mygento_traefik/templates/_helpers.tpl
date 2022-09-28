// allow nomad-pack to set the job name

[[- define "job_name" -]]
[[- if eq .mygento_traefik.job_name "" -]]
[[- .nomad_pack.pack.name | quote -]]
[[- else -]]
[[- .mygento_traefik.job_name | quote -]]
[[- end -]]
[[- end -]]