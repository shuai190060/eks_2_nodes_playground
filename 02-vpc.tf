resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # configuration to enable EFS
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "main"
  }

}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "igw"
  }

}

# private subnet
resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private-us-east-1a-subnet
  availability_zone = var.az[0]

  tags = {
    "Name"                                      = "private-${var.az[0]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private-us-east-1b-subnet
  availability_zone = var.az[1]

  tags = {
    "Name"                                      = "private-${var.az[1]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}


# public subnet
resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public-us-east-1a-subnet
  availability_zone       = var.az[0]
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "public-${var.az[0]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public-us-east-1b-subnet
  availability_zone       = var.az[1]
  map_public_ip_on_launch = true

  tags = {
    "Name"                                      = "public-${var.az[1]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}


# eip
resource "aws_eip" "nat" {
  count = 2
  vpc   = true

  tags = {
    "Name" = "EIP-${count.index + 1}"
  }

}

# nat gateway
resource "aws_nat_gateway" "nat" {
  count         = 2
  subnet_id     = element([aws_subnet.public-us-east-1a.id, aws_subnet.public-us-east-1b.id], count.index)
  allocation_id = element(aws_eip.nat.*.id, count.index)

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    "Name" = "nat"
  }

}

# route private
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
  }

  tags = {
    "Name" = "private"
  }

}

resource "aws_route_table_association" "private-us-east-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.private[0].id

}

resource "aws_route_table_association" "private-us-east-1b" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.private[1].id

}

# route public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "public"
  }


}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public.id

}