## Phyo Min Htun - phyominhtun1990@gmail.com
## All are testing purpose and using in some events (executing this code and building resources on AWS is your own responsibility)
## References:
## https://registry.terraform.io/modules/terraform-aws-modules/key-pair/aws/latest
## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
## https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
## https://github.com/terraform-aws-modules/terraform-aws-ec2-instance
## https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest

## VPC MODULE (Build aws vpc with private,public subnet with nat gateway)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.pri_sub
  public_subnets  = var.pub_sub

  enable_nat_gateway     = var.is_enable_natgw
  single_nat_gateway     = var.is_single_natgw
  one_nat_gateway_per_az = var.is_one_natgw_per_az


  tags = {
    Name        = "tf-vpc-demo"
    Environment = "demo"
  }
}

## AWS KEY_PAIR MODULE
resource "tls_private_key" "this" {
  algorithm = "RSA"
}
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = var.key_name ### Keys are not using anywhere.This is only for testing purpose
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5khFNg/jLsERa6kNlZSNe4wWLdGA0cweS+sbODUHydHzYGvLjKOnNFbJES1mYgjlgersF7TxE+6to7qsJ3MJgGHkf9ylTDMAmPvHm3EEbu4rJSoQhwOi8QRtz0ebnxV99COEfh6OSW3mCyLSGx5QtLJVuiYTW+QOU7tn81k17ks16+SKd0BWOpKTB/QOhLgK8ya3FqGosavb+RDzf3zxsep5TGADSLAafaP5a/Q/irV/Ualcc+yJRSgks4nAKh3qjPVXB7cEhYXpZVOk/dpJ6z2UFhtPgb3gvLyXF/KkssTMY0SZrevCC0gbI6Fn7IiLbdt0+kqv+6I0Fx4hXX9KqzFRiFYtkDy62/AS/GhGQlZUJqmbxjjV33j4oAhOYllBFljtAAs5WthvIvvIX7zLuf4mIREK+EZKihkYunYK+xc9RaaC1u77IN5+Z0Bc5zNm94jWimA292X8jge3h/DyQcnqyUGjxPb9dac23NqscKXFHskroIB4XOiBo1ESSAW0= demo@blahblah.com"

  tags = {
    Name        = "tf-ec2-keypair"
    Environment = "demo"
  }
}

## AWS EC2 RESOURCE
resource "aws_instance" "webserver" {
  count                  = length(module.vpc.public_subnets)
  ami                    = data.aws_ami.amazon.id
  instance_type          = var.instance_type
  key_name               = module.key_pair.this_key_pair_key_name
  subnet_id              = module.vpc.public_subnets[count.index]
  vpc_security_group_ids = [module.web_service_sg.this_security_group_id]

  tags = {
    Name        = "tf-ec2-${count.index + 1}"
    Environment = "demo-${count.index + 1}"
  }
}

## AWS EIP RESOURCE
resource "aws_eip" "lb" {
  count    = length(aws_instance.webserver)
  instance = aws_instance.webserver[count.index].id
  vpc      = var.eip_vpc
}

## AWS SG MODULE (HTTP and SSH)
#  custome rule security group allow module
module "web_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "web-server-sg"
  description = "Security group for web server with custom ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}