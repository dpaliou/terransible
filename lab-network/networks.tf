#Create VPC in eu-west-2
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master #provider alias
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

resource "aws_vpc" "vpc_master_paris" {
  provider             = aws.region-worker #provider alias
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

#Create Gateways
resource "aws_internet_gateway" "igw" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
}

resource "aws_internet_gateway" "igw-paris" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_master_paris.id
}

#Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

#Create subnet #1 in eu-west-2
resource "aws_subnet" "subnet_1" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0) #the 1st retrieved in the list
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
}

#Create subnet #2 in eu-west-2
resource "aws_subnet" "subnet_2" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 1) #the 2nd retrieved in the list
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
}

#Create subnet #1 in eu-west-3
resource "aws_subnet" "subnet_1_paris" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_master_paris.id
  cidr_block = "192.168.1.0/24"
}


##########################################################################################
##########################################################################################
##########################################################################################

###########################
#Initiate Peering connection request from eu-west-2
resource "aws_vpc_peering_connection" "euwest2-euwest3" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_master_paris.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
}
#Accept VPC peering request in eu-west-3 from eu-west-2
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.euwest2-euwest3.id
  auto_accept               = true
}

#Create route table in eu-west-2 - The VPCs be able to communicate
resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.euwest2-euwest3.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

#overwrite default route table of VPC(master) with our route table entries
#because when we created the VPC above, it created the default route over VPC, so we update the main routing table
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  route_table_id = aws_route_table.internet_route.id
  vpc_id         = aws_vpc.vpc_master.id
}

###########################
#Create route table in eu-west-3
resource "aws_route_table" "internet_route_paris" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_master_paris.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-paris.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.euwest2-euwest3.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

#overwrite default route table of VPC(worker) with our route table entries
resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  provider       = aws.region-worker
  route_table_id = aws_route_table.internet_route_paris.id
  vpc_id         = aws_vpc.vpc_master_paris.id
}

