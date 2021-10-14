## Security Group

resource "aws_security_group" "nodeapp_security_group" {
  name        = "${var.region}-nodeapp"
  description = "Terraform-managed nodeapp security group"
  vpc_id      = module.vpc.vpc_id

  # aws_launch_configuration.launch_configuration in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.region}-nodeapp-sg"
  }
}

resource "aws_security_group_rule" "nodeapp_allow_port80_inbound" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nodeapp_security_group.id
}

resource "aws_security_group_rule" "nodeapp_allow_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nodeapp_security_group.id
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "nodeapp-instance" {
  ami           = data.aws_ami.ubuntu.image_id
  instance_type = "t3a.small"

  tags = {
    Name      = "${var.region}-nodeapp"
    Terraform = "true"
  }
  key_name               = "troubleshooting"
  count                  = 1
  subnet_id              = module.vpc.public_subnets.0
  vpc_security_group_ids = [aws_security_group.nodeapp_security_group.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  user_data  = file("${path.root}/files/node-install.sh")
  depends_on = [module.vpc]
}
