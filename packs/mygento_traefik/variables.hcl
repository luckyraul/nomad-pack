variable "job_name" {
  description = "The name to use as the job name which overrides using the pack name."
  type        = string
  default     = ""
}

variable "job_type" {
  description = "The job type"
  type        = string
  default     = "system"
}

variable "node_class" {
  description = "Node Class Constraint"
  type        = string
  default     = ""
}

variable "proxy_to" {
  description = "The address to proxy in proxy mode"
  type        = string
  default     = ""
}

variable "proxy_from" {
  description = "The traeffik router config"
  type        = string
  default     = ""
}

variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["dc1"]
}

variable "traefik_task_resources" {
  description = "The resource to assign to the Traefik task."
  type        = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 200,
    memory = 288,
  }
}

variable "acme_email" {
  description = "The region where the job should be placed."
  type        = string
}
