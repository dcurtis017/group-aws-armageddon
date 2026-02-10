# Prerequisites

- [] - You need to have the aws cli configured
- [] - You need to create your own `backend.hcl` file
- [] - You need to create your own `terraform.tfvars` file
- [] - Purchase a domain name and create a hosted zone - If you haven't done this prior to the labs then you can created the hosted zone with terraform. If you do this then consider a PR for making adding the hosted zone configurable

**You need a backend.hcl and terraform.tfvars in each Lab directory**

**backend.hcl**

```hcl
bucket = "name-of-bucket-for-terraform-state"
key    = "class7/armageddon/lab1.tfstate"
region = "us-east-1"
use_lockfile = true
```

**terraform.tfvars**

```tfvars
region = "us-east-1"

default_tags = {
  Environment = "Armageddon-Lab1"
  ManagedBy   = "Terraform"
  Owner       = "you-name"
}

instance_type = "t2.micro"

ami_id = "ami-08982f1c5bf93d976"

name_prefix = "armageddon-lab1"

db_engine          = "mysql"
db_instance_class  = "db.t3.micro"
db_name            = "labdb"
db_username        = "admin"
db_password        = "Password1234Obviously"
sns_email_endpoint = "email@me.com"

vpc_endpoint_services = [
  "secretsmanager",
  "logs",
  "ssm",
  "ec2messages",
  "ssmmessages",
  "monitoring",
  "kms"
]

root_domain_name       = "chewbacca.growl"
enable_waf             = false
enable_alb_access_logs = true
enable_waf_logging     = true
```

# General Todos

- [] - Use a variable for the secret header value
- [] - Add appropriate outputs for labs# Issues/General Todo
- [] Lab 3 I have to run the apply twice becaue of Error: creating EC2 Transit Gateway Route -- need to resolve this. I think it's a race condition
- [] `restrict_alb_to_cloudfront` does not result in allow https from anywhere to work
  - the broad rule was required for lab3b to work -- need to understand why
- [] Lab 3 does not work with custom header
- [] Move Cloudfront logs to S3 instead of cloudwatch?
- [] CloudFront and WAF Cloudwatch logs empty
- [] Lab2 refresh hit

# Running Labs

**Lab 1 will be used as an example**

```bash
# Navigate to lab directory
cd Lab1/
terraform init -backend-config=backend.hcl
terraform validate
terraform plan
terraform apply --auto-approve

# if you make changes to a module or need an updated version of a remote module run
terraform init -upgrade

# teardown
terraform destroy --auto-approve

```

# Lab 1

## Todo

- [] Deliverables
- [] Questions

## Deliverables

# Lab 2

- This lab uses cloudfront and ACM. Your certificate must be created in us-east-1. If you're using a region other than us-east-1 for the rest of your project then you'll need to pass a provider with the region set to us-east-1 to the acm module.

## Todo

- [x] Deliverables for 2B
- [x] Deliverables for 2A
- [x] 2B Class Questions
- [x] Be a Man
- [x] Be a Man A
- [x] Be a Man B
- [] Lab 2 Be a Man C -- Need help

## Deliverables

# Lab 3

https://aws.amazon.com/blogs/networking-and-content-delivery/latency-based-routing-leveraging-amazon-cloudfront-for-a-multi-region-active-active-architecture/

https://mahira-technology.medium.com/streamlining-network-visibility-a-comprehensive-guide-to-creating-vpc-flow-logs-with-terraform-6622b6f7a32b

https://aws.plainenglish.io/project-trail-using-terraform-to-deploy-aws-cloudtrail-8f60d4a48a0a

## To Do

- [x] Create Auth
- [x] Create Japanese Resources -- Test
- [x] Create provider so we can make sure ACM cert is in us-east-1
- [x] Add Brazil resources
- [x] Make sure instances are in private subnets
- [x] Cloudfront part
- [x] Transit gateways
- [x] Make sure Brazil can connect to db in Tokyo
- [x] Check NACL subnet association
- [] VPC flow logs
- [] CloudTrail
  \*\*Will routes auto-propogate if I don't put them in the route table
  \*\* leave restricted to cf turn off custom header

# Modules

When you change a module, make sure to run `terraform init -upgrade` so your project will get the latest version of the module.

## To Do

- [] Remove enabled_alb_tls since it's not used

## Module Overview

| Module                                       | Purpose                                                                             |
| -------------------------------------------- | ----------------------------------------------------------------------------------- |
| [VPC](modules/vpc/README.md)                 | Creates VPC with public/private subnets, internet gateway, and optional NAT gateway |
| [RDS](modules/rds/README.md)                 | Provisions managed relational database with secure access and credential management |
| [Web Service](modules/web_service/README.md) | Deploys EC2 instance with Application Load Balancer and security groups             |
| [ACM](modules/acm/README.md)                 | Creates and validates SSL/TLS certificate with DNS validation via Route53           |
| [CloudFront](modules/cloudfront/README.md)   | Configures global CDN distribution with caching and origin protection               |
| [WAF](modules/waf/README.md)                 | Implements Web Application Firewall with DDoS protection and logging                |

For detailed information about each module including variables, outputs, and usage examples, refer to the individual module README files linked above.
