variable "aws_region" {
  type        = string
  description = "AWS region where the deployment machines will be created"
}

variable "availability_zones" {
  type        = list(string)
  description = "Used availability zones"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids to attach the machines network interface"
}

variable "iscsi_srv_images" {
  type = map(string)

  default = {
    "us-east-1"    = "ami-027447d2b7312df2d"
    "us-east-2"    = "ami-099a51d3b131f3ce2"
    "us-west-1"    = "ami-0f213357578720889"
    "us-west-2"    = "ami-0fc86417df3e0f6d4"
    "ca-central-1" = "ami-0811b93a30ab570f7"
    "eu-central-1" = "ami-024f50fdc1f2f5603"
    "eu-west-1"    = "ami-0ca96dfbaf35b0c31"
    "eu-west-2"    = "ami-00189dbab3fd43af2"
    "eu-west-3"    = "ami-00e70e3421f053648"
  }
}

variable "iscsi_count" {
  type        = number
  description = "Number of iscsi machines to deploy"
}

variable "instance_type" {
  type        = string
  description = "The instance type of iscsi server node."
  default     = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "AWS key pair name"
}

variable "security_group_id" {
  type        = string
  description = "Security group id"
}

variable "private_key_location" {
  type        = string
  description = "Path to a SSH private key used to connect to the created machines"
}

variable "host_ips" {
  description = "List of ip addresses to set to the machines"
  type        = list(string)
}

variable "lun_count" {
  description = "Number of LUN (logical units) to serve with the iscsi server. Each LUN can be used as a unique sbd disk"
  type        = number
  default     = 3
}

variable "reg_code" {
  description = "If informed, register the product using SUSEConnect"
  default     = ""
}

variable "reg_email" {
  description = "Email used for the registration"
  default     = ""
}

variable "reg_additional_modules" {
  description = "Map of the modules to be registered. Module name = Regcode, when needed."
  type        = map(string)
  default     = {}
}

variable "ha_sap_deployment_repo" {
  description = "Repository url used to install HA/SAP deployment packages"
  type        = string
}

variable "additional_packages" {
  description = "extra packages which should be installed"
  default     = []
}

variable "provisioner" {
  description = "Used provisioner option. Available options: salt. Let empty to not use any provisioner"
  default     = "salt"
}

variable "background" {
  description = "Run the provisioner execution in background if set to true finishing terraform execution"
  type        = bool
  default     = false
}

variable "qa_mode" {
  description = "Whether or not to install the HA/SAP packages from the `ha_sap_deployment_repo`"
  type        = bool
  default     = false
}

variable "on_destroy_dependencies" {
  description = "Resources objects needed in the on_destroy script (everything that allows ssh connection)"
  type        = any
  default     = []
}
