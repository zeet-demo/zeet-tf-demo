terraform {
  required_providers {
    zeet = {
      source  = "zeet-dev/zeet"
      version = "~> 1.0.0"
    }
  }
}

variable "team_id" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "region" {
  type = string
}

resource "zeet_group" "group" {
  team_id = var.team_id
  name    = "my-group"
}

resource "zeet_group_subgroup" "subgroup" {
  team_id  = var.team_id
  group_id = zeet_group.group.id
  name     = "my-subgroup"
}

data "zeet_blueprint" "terraform" {
  slug = "terraform-module"
}

resource "zeet_project" "terraform" {
  team_id     = var.team_id
  group_id    = zeet_group.group.id
  subgroup_id = zeet_group_subgroup.subgroup.id

  name         = "my-terraform"
  blueprint_id = data.zeet_blueprint.terraform.id
  enabled      = false // draft mode

  deploys = [{
    default_workflow_steps = ["DRIVER_PLAN", "DRIVER_APPROVE", "DRIVER_APPLY"]
    terraform = jsonencode({
      target = {
        moduleName = "cluster",
        stateBackend = {
          s3Bucket = {
            awsAccountId = var.aws_account_id,
            region       = var.region,
            bucketName   = format("zeet-tf-%s-%s", var.aws_account_id, var.region),
            key          = "cluster.tfstate",
          }
        },
        provider = {
          awsAccountId = var.aws_account_id,
          region       = var.region
        }
      },
      blueprint = {
        source = {
          terraformModule = {
            source = "https://github.com/zeet-demo/terraform-test"
          },
        },
      },
    })
    variables = jsonencode([
      { name = "min", value = "0", type = "INTEGER" },
      { name = "max", value = "100", type = "INTEGER" },
    ])
  }]

  workflow = {
    steps = jsonencode([{ action = "ORCHESTRATION_DEPLOY" }])
  }
}

output "project_id" {
  description = "value of the project_id used in apiv1"
  value       = zeet_project.terraform.id
}
