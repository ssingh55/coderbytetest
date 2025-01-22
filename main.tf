provider "aws" {
    region = "us-east-1"
}

# vpc module
module "vpc" {
    source = "terraform-aws-modules/vpc/aws"

    name = "k8s-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    enable_nat_gateway = true
    
    tags = {
        Name = "k8s-vpc"
    }
}

# eks cluster and iam role
resource "aws_iam_role" "eks_cluster" {
    name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster.name
}

# EKS node group iam role
resource "aws_iam_role" "eks_nodes_group" {
    name = "eks-node-group-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_nodes_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.eks_nodes_group.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks_nodes_group.name
}

# eks cluster
resource "aws_eks_cluster" "main" {
    name = "k8s-cluster"
    role_arn = aws_iam_role.eks_cluster.arn
    version = "1.31"

    vpc_config {
        subnet_ids = module.vpc.private_subnets
        endpoint_private_access = true
        endpoint_public_access = true
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_policy,
        module.vpc
    ]
}

# eks node group
resource "aws_eks_node_group" "main" {
    cluster_name = aws_eks_cluster.main.name
    node_group_name = "k8s-node-group"
    node_role_arn = aws_iam_role.eks_nodes_group.arn
    subnet_ids = module.vpc.private_subnets

    scaling_config {
        desired_size = 1
        max_size = 1
        min_size = 1
    }

    instance_types = ["t2.micro"]

    depends_on = [
        aws_iam_role_policy_attachment.eks_worker_node_policy,
        aws_iam_role_policy_attachment.eks_cni_policy,
        aws_iam_role_policy_attachment.ec2_container_registry_read_only
    ]
}

output "cluster_endpoint" {
    value = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
    value = aws_eks_cluster.main.name
}

output "cluster_certificate_authority_data" {
    value = aws_eks_cluster.main.certificate_authority[0].data
}