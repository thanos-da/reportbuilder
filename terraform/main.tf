provider "aws" {
  region = var.aws_region
}

# Get the Latest Ubuntu 24.04 AMI
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance Configuration
resource "aws_instance" "DMA_app" {
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = var.instance_type
  subnet_id              = var.existing_subnet_id          # Using variable directly
  vpc_security_group_ids = [var.existing_security_group_id] # Using variable directly
  iam_instance_profile   = var.existing_iam_instance_profile_name # Using variable directly
  key_name               = var.key_name

  root_block_device {
    volume_size           = var.vol_size
    volume_type           = var.vol_type
    delete_on_termination = false
  }

  tags = {
    Name        = "DMA_Application"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the DMA application instance"
  value       = aws_instance.DMA_app.public_ip
}

output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.DMA_app.id
}
