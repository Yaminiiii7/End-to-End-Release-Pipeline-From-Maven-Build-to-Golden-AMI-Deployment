packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.8"
    }
  }
}

#####################
# VARIABLES
#####################

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "geo-service-ami"
}

#####################
# LOCALS
#####################

locals {
  build_timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

#####################
# SOURCE AMI
#####################

source "amazon-ebs" "ubuntu" {
  region        = var.region
  instance_type = var.instance_type
  ssh_username  = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  ami_name = "${var.ami_name_prefix}-${local.build_timestamp}"

  tags = {
    Name    = var.ami_name_prefix
    Project = "geo-service"
    BuiltBy = "packer"
  }
}

#####################
# BUILD
#####################

build {
  sources = ["source.amazon-ebs.ubuntu"]

  #################################
  # COPY APPLICATION ARTIFACT
  #################################

  provisioner "file" {
    source      = "../target/geo-service-1.0.0.jar"
    destination = "/tmp/geo-service.jar"
  }

  #################################
  # COPY SYSTEMD SERVICE FILE
  #################################

  provisioner "file" {
    source      = "files/geo-service.service"
    destination = "/tmp/geo-service.service"
  }

  #################################
  # INSTALL JAVA
  #################################

  provisioner "shell" {
    script = "scripts/install_java.sh"
  }

  #################################
  # SETUP GEO-SERVICE + SYSTEMD
  #################################

  provisioner "shell" {
    script = "scripts/setup_geo_service.sh"
  }

  #################################
  # INSTALL NODE EXPORTER
  #################################

  provisioner "shell" {
    script = "scripts/install_node_exporter.sh"
  }
}
