terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }

    backend "s3" {
        bucket = "dev-vfc-bucket-27"
        key = "StateFiles/state.tfstate"
        region = "eu-west-3"
    }
}