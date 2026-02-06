# db secret and values
output "db_secret_name" {
  value = module.rds.db_secret_name
}

output "tgw_id" {
  value = module.tgw.tgw_id
}

output "tgw_peering_attachment_id" {
  value = module.tgw.tgw_peering_attachment_ids[0]
}

output "db_secret_id" {
  value = module.rds.db_secret_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "db_endpoint" {
  value = module.rds.rds_endpoint
}
