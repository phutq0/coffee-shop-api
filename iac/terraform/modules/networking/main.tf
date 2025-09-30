terraform {
  required_version = ">= 1.3.0"
}


# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = element(data.aws_availability_zones.available.names, each.key)
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.key}"
    Tier = "public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each          = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(data.aws_availability_zones.available.names, each.key)

  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT + EIPs
resource "aws_eip" "nat" {
  count      = var.enable_nat_per_az ? length(aws_subnet.public) : 1
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
  tags       = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_per_az ? length(aws_subnet.public) : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public)[*].id, count.index)
  tags          = merge(var.tags, { Name = "${var.name}-nat-${count.index}" })
}

# Private Route Tables (per AZ if per-AZ NAT else single)
resource "aws_route_table" "private" {
  count  = var.enable_nat_per_az ? length(aws_subnet.private) : 1
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt-${count.index}" })
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat_per_az ? length(aws_route_table.private) : 1
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  for_each  = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = (
    var.enable_nat_per_az
    ? element(aws_route_table.private[*].id, tonumber(each.key))
    : aws_route_table.private[0].id
  )
}

# VPC Endpoints
resource "aws_vpc_endpoint" "s3" {
  count             = var.vpc_endpoints.s3 ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], aws_route_table.private[*].id)
  tags              = merge(var.tags, { Name = "${var.name}-vpce-s3" })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.vpc_endpoints.ecr ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name}-vpce-ecr-api" })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.vpc_endpoints.ecr ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name}-vpce-ecr-dkr" })
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name}-endpoints-sg"
  description = "Allow HTTPS to interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-endpoints-sg" })
}

# Flow Logs (CloudWatch)
resource "aws_cloudwatch_log_group" "flow" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.name}-flow"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count                = var.enable_vpc_flow_logs ? 1 : 0
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow[0].arn
  iam_role_arn         = aws_iam_role.flow_logs[0].arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
}

# Database Subnets
resource "aws_subnet" "db" {
  for_each          = { for idx, cidr in var.db_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(data.aws_availability_zones.available.names, each.key)

  tags = merge(var.tags, {
    Name = "${var.name}-db-${each.key}"
    Tier = "db"
  })
}

# NACLs (optional)
resource "aws_network_acl" "public" {
  count      = var.enable_nacls ? 1 : 0
  vpc_id     = aws_vpc.this.id
  subnet_ids = values(aws_subnet.public)[*].id
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(var.tags, { Name = "${var.name}-public-nacl" })
}

resource "aws_network_acl" "private" {
  count      = var.enable_nacls ? 1 : 0
  vpc_id     = aws_vpc.this.id
  subnet_ids = values(aws_subnet.private)[*].id
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }
  tags = merge(var.tags, { Name = "${var.name}-private-nacl" })
}

resource "aws_network_acl" "db" {
  count      = var.enable_nacls ? 1 : 0
  vpc_id     = aws_vpc.this.id
  subnet_ids = values(aws_subnet.db)[*].id
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }
  tags = merge(var.tags, { Name = "${var.name}-db-nacl" })
}
