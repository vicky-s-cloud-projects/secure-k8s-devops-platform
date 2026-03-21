data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones  = ["eu-west-2a", "eu-west-2b"]
}

module "jenkins_sg" {
  source      = "./modules/security-group"
  name        = "jenkins-sg"
  description = "Jenkins Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },

    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "master_sg" {
  source      = "./modules/security-group"
  name        = "master-sg"
  description = "K3s Master SG"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [

    # SSH
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    },

    # Kubernetes API
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },

    # Kubelet
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },

    # HTTP / HTTPS
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },

    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },

    # Internal cluster traffic
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },

    {
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    },

    # Cilium VXLAN
    {
      from_port   = 8472
      to_port     = 8472
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    },

    # Cilium health / hubble
    {
      from_port   = 4240
      to_port     = 4240
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },

    {
      from_port   = 4244
      to_port     = 4244
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },

    {
      from_port   = 32550
      to_port     = 32550
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    },

    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    }

  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "worker_sg" {
  source      = "./modules/security-group"
  name        = "worker-sg"
  description = "K3s Worker SG"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_ip]
    },
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 31124
      to_port     = 31124
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 8472
      to_port     = 8472
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    },

    # Cilium health / hubble
    {
      from_port   = 4240
      to_port     = 4240
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },

    {
      from_port   = 4244
      to_port     = 4244
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "master" {
  source              = "./modules/ec2"
  name                = "k3s-master"
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = "m7i-flex.large"
  subnet_id           = module.vpc.public_subnet_ids[0]
  security_group_ids  = [module.master_sg.security_group_id]
  key_name            = var.key_name
}

module "worker1" {
  source              = "./modules/ec2"
  name                = "k3s-worker-1"
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = "t3.small"
  subnet_id           = module.vpc.public_subnet_ids[1]
  security_group_ids  = [module.worker_sg.security_group_id]
  key_name            = var.key_name
}

module "worker2" {
  source              = "./modules/ec2"
  name                = "k3s-worker-2"
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = "t3.small"
  subnet_id           = module.vpc.public_subnet_ids[1]
  security_group_ids  = [module.worker_sg.security_group_id]
  key_name            = var.key_name
}

module "jenkins" {
  source              = "./modules/ec2"
  name                = "jenkins-server"
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = "t3.micro"
  subnet_id           = module.vpc.public_subnet_ids[0]
  security_group_ids  = [module.jenkins_sg.security_group_id]
  key_name            = var.key_name
}