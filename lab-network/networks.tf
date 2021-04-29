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

