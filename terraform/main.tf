variable "github_token" {
  description = "The GitHub Token to be used for the CodePipeline"
  type        = "string"
}

provider "aws" {
  region  = "eu-central-1"
  version = "2.7"
}
