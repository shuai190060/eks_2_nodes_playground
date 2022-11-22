variable "cluster_name" {
  default = "demo"

}

variable "cluster_version" {
  default = "1.22"

}

variable "private-us-east-1a-subnet" {
  default = "10.0.0.0/19"

}

variable "private-us-east-1b-subnet" {
  default = "10.0.32.0/19"

}

variable "public-us-east-1a-subnet" {
  default = "10.0.64.0/19"

}

variable "public-us-east-1b-subnet" {
  default = "10.0.96.0/19"

}

variable "az" {
  default = ["us-east-1a", "us-east-1b"]

}