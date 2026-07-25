# terraform settings
terraform {
    required_providers {
        aws = {
            source = "hasicorp/aws"
            version = ">=4.16"
        }
    }

    required_version = ">=1.2.0"
}

# providers
provider "aws" {
    region = "ap-south-1"
}

# resources
res "aws_instance" "webserver" {
    ami = "provde the AMI here for your region"
    instance_type = "t2.micro"
    tags = {
        name = "ExampleServer"
    }
}