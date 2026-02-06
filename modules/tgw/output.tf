output "tgw_id" {
  value = aws_ec2_transit_gateway.tgw.id
}

output "tgw_arn" {
  value = aws_ec2_transit_gateway.tgw.arn
}

output "tgw_subnet_ids" {
  value = aws_subnet.tgw_subnets[*].id
}

output "tgw_route_table_id" {
  value = aws_route_table.tgw_route_table.id
}

output "tgw_peering_attachment_ids" {
  value = aws_ec2_transit_gateway_peering_attachment.tgw_peering_attachment[*].id
}
