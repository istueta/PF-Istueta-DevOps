variable "aws_region" {
  description = "Region de AWS"
  type = string
  default = "us-east-1"
}
variable "project_name" {
  description = "Prefijo para nombrar recursos"
  type = string
  default = "pf-devops"
}
variable "cluster_version" {
  description = "Version de Kubernetes soportada por EKS"
  type = string
  default = "1.31"
}
variable "vpc_cidr" {
  description = "Rango privado de la VPC"
  type = string
  default = "10.0.0.0/16"
}
variable "node_instance_types" {
  description = "Tipos de instancia para nodos"
  type = list(string)
  default = ["t3.medium"]
}
variable "desired_size" {
  description = "Cantidad deseada de nodos"
  type = number
  default = 1
}
variable "min_size" {
  type = number
  default = 1
}
variable "max_size" {
  type = number
  default = 2
}
