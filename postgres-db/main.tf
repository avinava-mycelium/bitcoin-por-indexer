# ------------------------------------------------------------------------------
# LAUNCH A POSTGRESQL CLOUD SQL PUBLIC IP INSTANCE
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# CONFIGURE OUR GCP CONNECTION
# ------------------------------------------------------------------------------

provider "google-beta" {
  project = var.project_id
  region  = var.region
  credentials = file("service_account.json")
}

terraform {
  # This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 1.0.x code.
  required_version = ">= 0.12.26"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 3.57.0"
    }
  }
}

# ------------------------------------------------------------------------------
# CREATE A RANDOM SUFFIX AND PREPARE RESOURCE NAMES
# ------------------------------------------------------------------------------

# resource "random_id" "name" {
#   byte_length = 2
# }

# locals {
#   # If name_override is specified, use that - otherwise use the name_prefix with a random string
#   instance_name = var.name_override == null ? format("%s-%s", var.name_prefix, random_id.name.hex) : var.name_override
# }

# ------------------------------------------------------------------------------
# CREATE DATABASE INSTANCE WITH PUBLIC IP
# ------------------------------------------------------------------------------

module "sql-db" {
  source  = "GoogleCloudPlatform/sql-db/google"
  version = "8.0.0"
  # insert the 6 required variables here
}


module "postgres" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/gruntwork-io/terraform-google-sql.git//modules/cloud-sql?ref=v0.2.0"
  source = "github.com/gruntwork-io/terraform-google-sql.git//modules/cloud-sql?ref=v0.6.0"

  project = var.project_id
  region  = var.region
  name    = var.instance_name
  db_name = var.db_name

  engine       = var.postgres_version
  machine_type = var.machine_type
  disk_size     = 3000


  # These together will construct the master_user privileges, i.e.
  # 'master_user_name' IDENTIFIED BY 'master_user_password'.
  # These should typically be set as the environment variable TF_VAR_master_user_password, etc.
  # so you don't check these into source control."
  master_user_password = var.master_user_password
  master_user_name     = var.master_user_name

  # To make it easier to test this example, we are giving the instances public IP addresses and allowing inbound
  # connections from anywhere. We also disable deletion protection so we can destroy the databases during the tests.
  # In real-world usage, your instances should live in private subnets, only have private IP addresses, and only allow
  # access from specific trusted networks, servers or applications in your VPC. By default, we recommend setting
  # deletion_protection to true, to ensure database instances are not inadvertently destroyed.
  enable_public_internet_access = true
  deletion_protection           = false

  # Default setting for this is 'false' in 'variables.tf'
  # In the test cases, we're setting this to true, to test forced SSL.
  require_ssl = var.require_ssl

  authorized_networks = [
    {
      name  = "allow-all-inbound"
      value = "0.0.0.0/0"
    },
  ]

  # Set test flags
  # Cloud SQL will complain if they're not applicable to the engine
  # database_flags = [
  #   {
  #     name  = "autovacuum"
  #     value = true
  #   },
  # ]

  custom_labels = {
    name = "postgres-bitcoin-por-indexer"
  }
}