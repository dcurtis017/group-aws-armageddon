# RDS Module

## Purpose

Provisions a managed relational database instance with configurable engine, automatic backups, enhanced monitoring, and secure access via security groups and AWS Secrets Manager integration.

## Variables

| Variable                     | Type         | Default    | Description                                        |
| ---------------------------- | ------------ | ---------- | -------------------------------------------------- |
| `name_prefix`                | string       | "myapp"    | Prefix for naming resources                        |
| `db_engine`                  | string       | _required_ | Database engine type (mysql, postgres, etc.)       |
| `db_instance_class`          | string       | _required_ | Instance class (e.g., db.t3.micro)                 |
| `db_name`                    | string       | _required_ | Initial database name                              |
| `db_username`                | string       | _required_ | Master username for the database                   |
| `db_password`                | string       | _required_ | Master password for the database                   |
| `rds_db_subnet_ids`          | list(string) | _required_ | Subnet IDs for RDS placement                       |
| `allowed_sg_ids`             | list(string) | _required_ | Security groups allowed to connect to RDS          |
| `logs_bucket`                | string       | _required_ | S3 bucket for enhanced monitoring logs             |
| `ssm_and_secret_prefix`      | string       | "lab"      | Prefix for SSM Parameter Store and Secrets Manager |
| `db_is_publicly_accessible`  | bool         | false      | Whether database is publicly accessible            |
| `skip_db_snapshot_on_delete` | bool         | _varies_   | Skip final snapshot on deletion                    |

## Outputs

| Output                  | Description                                            |
| ----------------------- | ------------------------------------------------------ |
| `rds_security_group_id` | Security group ID for RDS                              |
| `rds_instance_arn`      | ARN of the RDS instance                                |
| `rds_instance_id`       | Identifier of the RDS instance                         |
| `db_secret_name`        | AWS Secrets Manager secret name containing credentials |

## Resources Created

- RDS Database Instance
- Security Group for RDS
- DB Subnet Group
- Enhanced Monitoring IAM Role
- AWS Secrets Manager secret for database credentials
- SSM Parameter Store entries for configuration
