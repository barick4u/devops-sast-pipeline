module "vpc" {
source = "terraform-aws-modules/vpc/aws"
version = "5.21.0"
name = "my-vpc"
cidr = "10.0.0.0/16"
azs = ["ap-south-1", "ap-south-2"]
public_subnet = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet =["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway = true
  enable_vpn_gateway = true

tag = {
	Name = "myvpcbestone"
`	Enviornment = "Dev"
} 


