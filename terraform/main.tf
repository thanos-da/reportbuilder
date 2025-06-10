provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "rails_app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  root_block_device {
    volume_size = var.vol_size         # Size in GB
    volume_type = var.vol_type  
    delete_on_termination = true
  }

  tags = {
    Name = "Report Builder"
  }
}

output "instance_public_ip" {
  value = aws_instance.rails_app.public_ip
}
