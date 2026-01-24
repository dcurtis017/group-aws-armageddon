# VPC Module

## Purpose

Creates a Virtual Private Cloud (VPC) with configurable public and private subnets, internet gateway, and optional NAT gateway for secure network isolation and management.

## Variables

| Variable              | Type         | Default                      | Description                                        |
| --------------------- | ------------ | ---------------------------- | -------------------------------------------------- |
| `region`              | string       | "us-west-2"                  | The AWS region to deploy resources in              |
| `vpc_cidr`            | string       | "10.32.0.0/16"               | The CIDR block for the VPC                         |
| `public_subnets`      | list(string) | []                           | List of public subnet CIDR blocks                  |
| `private_subnets`     | list(string) | []                           | List of private subnet CIDR blocks                 |
| `availability_zones`  | list(string) | ["us-east-1a", "us-east-1b"] | Availability Zones list (match count with subnets) |
| `name_prefix`         | string       | "myapp"                      | Prefix for naming resources                        |
| `include_nat_gateway` | bool         | false                        | Whether to include a NAT Gateway in the VPC        |

## Outputs

| Output               | Description                |
| -------------------- | -------------------------- |
| `vpc_id`             | The ID of the VPC          |
| `public_subnet_ids`  | List of public subnet IDs  |
| `private_subnet_ids` | List of private subnet IDs |

## Resources Created

- VPC with configurable CIDR block
- Internet Gateway for public subnet traffic
- Public Subnets (with public IP assignment enabled)
- Private Subnets
- NAT Gateway and Elastic IP (optional)
