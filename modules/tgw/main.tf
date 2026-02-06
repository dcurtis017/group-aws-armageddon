terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_subnet" "tgw_subnets" {
  count                   = length(var.subnets)
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-tgw-subnet-${var.availability_zones[count.index]}"
  }
}

# local route should be created by provider
resource "aws_route_table" "tgw_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-tgw-rt"
  }
}

resource "aws_route_table_association" "tgw_rt_associations" {
  count          = length(aws_subnet.tgw_subnets)
  subnet_id      = aws_subnet.tgw_subnets[count.index].id
  route_table_id = aws_route_table.tgw_route_table.id
}

resource "aws_ec2_transit_gateway" "tgw" {
  description = var.gateway_description
  tags = {
    Name = "${var.name_prefix}-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = var.vpc_id
  subnet_ids         = aws_subnet.tgw_subnets[*].id
  tags = {
    Name = "${var.name_prefix}-tgw-vpc-attachment"
  }
}

# TODO: Allow for multiple peers
# The peer is another TGW you want to allow to connect to you
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_peering_attachment" {
  count                   = var.create_peering_attachment ? 1 : 0
  transit_gateway_id      = aws_ec2_transit_gateway.tgw.id
  peer_region             = var.peer_region
  peer_account_id         = var.peer_account_id != null ? var.peer_account_id : data.aws_caller_identity.current.account_id
  peer_transit_gateway_id = var.peer_transit_gateway_id
  tags = {
    Name = var.peer_attachment_name
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tgw_peering_attachment_accepter" {
  count                         = var.create_peering_attachment_acceptor ? 1 : 0
  transit_gateway_attachment_id = var.tgw_peering_attachment_id
  tags = {
    Name = "${var.name_prefix}-tgw-peering-attachment-accepter"
  }
}

resource "aws_ec2_transit_gateway_route" "tgw_peering_attachment_route" {
  count                          = var.create_peering_attachment ? 1 : 0
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw.association_default_route_table_id
  destination_cidr_block         = var.peer_cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tgw_peering_attachment[0].id
}

resource "aws_ec2_transit_gateway_route" "tgw_peering_attachment_acceptor_route" {
  count                          = var.create_peering_attachment_acceptor ? 1 : 0
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw.association_default_route_table_id
  destination_cidr_block         = var.peer_cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tgw_peering_attachment_accepter[0].id
}
