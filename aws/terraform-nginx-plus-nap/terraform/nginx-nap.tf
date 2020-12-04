data "aws_ami" "nginx-nap" {
  most_recent = true
  owners = ["679593333241"] # F5

  filter {
    name   = "name"
    values = ["nginx-plus-app-protect-ami-centos**"]
  }

}

resource "aws_autoscaling_group" "nginx-nap" {
  name                 = "nginx-nap-asg"
  launch_configuration = aws_launch_configuration.nginx-nap.name
  desired_capacity     = 2
  min_size             = 1
  max_size             = 4
  vpc_zone_identifier  = [module.vpc.public_subnets[1]]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "nginx-nap-autoscale"
      propagate_at_launch = true
    },
    {
      key                 = "Env"
      value               = "consul"
      propagate_at_launch = true
    },
    {
      key                 = "UK-SE"
      value               = "arch"
      propagate_at_launch = true
    }
  ]

}

resource "aws_launch_configuration" "nginx-nap" {
  name_prefix                 = "nginx-nap-"
  image_id                    = data.aws_ami.nginx-nap.id
  instance_type               = "t3.large"
  associate_public_ip_address = true

  security_groups      = [aws_security_group.nginx.id]
  key_name             = aws_key_pair.demo.key_name
  user_data            = file("../scripts/nginx.sh")
  iam_instance_profile = aws_iam_instance_profile.consul.name


  lifecycle {
    create_before_destroy = true
  }
}