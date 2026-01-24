locals {
  db_secret_name = "${var.ssm_and_secret_prefix}/rds/mysql"
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_sg_allow_all_outbound" {
  security_group_id = aws_security_group.rds_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "rds_sg_allow_mysql_inbound" {
  count                        = length(var.allowed_sg_ids)
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = var.allowed_sg_ids[count.index]
}

resource "aws_db_subnet_group" "lab1_rds_subnet_group" {
  name       = "${var.name_prefix}-rds-subnet-group"
  subnet_ids = var.rds_db_subnet_ids
  tags = {
    Name = "${var.name_prefix}-rds-subnet-group"
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "${var.name_prefix}-rds-instance"
  db_subnet_group_name   = aws_db_subnet_group.lab1_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  allocated_storage      = 20

  engine         = var.db_engine
  instance_class = var.db_instance_class
  db_name        = var.db_name
  username       = var.db_username
  password       = var.db_password

  publicly_accessible = var.db_is_publicly_accessible
  skip_final_snapshot = var.skip_db_snapshot_on_delete

  # TODO: add multi_az, backups and monitoring

  tags = {
    Name = "${var.name_prefix}-rds-instance"
  }
}

resource "aws_ssm_parameter" "lab_1_db_endpoint_param" {
  name  = "/${var.ssm_and_secret_prefix}/db/endpoint"
  type  = "String"
  value = aws_db_instance.rds_instance.address

  tags = {
    Name = "${var.name_prefix}-param-db-endpoint"
  }
}

resource "aws_ssm_parameter" "lab_1_db_port_param" {
  name  = "/${var.ssm_and_secret_prefix}/db/port"
  type  = "String"
  value = tostring(aws_db_instance.rds_instance.port)

  tags = {
    Name = "${var.name_prefix}-param-db-port"
  }
}

resource "aws_ssm_parameter" "lab_1_db_name_param" {
  name  = "/${var.ssm_and_secret_prefix}/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${var.name_prefix}-param-db-name"
  }
}

resource "aws_secretsmanager_secret" "lab_1_db_secret" {
  name                    = local.db_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "lab_1_db_secret_version" {
  secret_id = aws_secretsmanager_secret.lab_1_db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = var.db_engine
    host     = aws_db_instance.rds_instance.address
    port     = aws_db_instance.rds_instance.port
    dbname   = var.db_name
  })
}
