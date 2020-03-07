variable "github_token" {
  description = "The GitHub Token to be used for the CodePipeline"
  type        = "string"
  default     = "0157d642e9e53e94f1ddc8ea52d2f5bd54e96e74"
}

variable "region" {
  description = "region to deploy to"
  type        = "string"
  default     = "us-east-1"
}

variable "github-repo" {
  default = "green-blue-ecs-example"
}

variable "github-owner" {
  default = "ElAntagonista"
}

provider "aws" {
  region = "${var.region}"
  #version = "2.7"
}

