variable "vpc_cidr" {
  type    = string
  default = "10.20.30.0/24"
}

variable "pub_subnet_cidr_1" {
  type    = string
  default = "10.20.30.0/25"
}

variable "pub_subnet_cidr_2" {
  type    = string
  default = "10.20.30.128/25"
}

variable "inst_type" {
  type    = string
  default = "t3.nano"
}

variable "ssh_pubkey" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCk5Zbz9NWgmkT2SZI+2U14vq21xDkyTndK79j11yoov7TfIRagLr0iKM8FAN2yrLg51vxDKH/Nt+TJxoQUwRGAYzxA1Tc/u8h92L3011MsADLwkGKemj8XD2xx8TB60yEF0SLTs/d+tyQ71eRkXcaYOEjbXBEL0/crZ41oAKX7Z3zjArpHMqpu5qVmMWVVz41zp9IYalIGsjq3Rdu/J2YoA4g8/iRk9E41sMhoUjT1O3aLvUD/RuDqgBRL0l7A5Xbz9Ye/uOdy2Cu2pfjkikqjDLLuOITOxh/F0+2IjyZROqcw5rrZ/VAj2V3quP07eg/65cRiiwRgsxOOxbKPJ1lZ laboratory"
}

