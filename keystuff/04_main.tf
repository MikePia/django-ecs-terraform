
resource "aws_instance" "ec2_key_example" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"
  key_name = "key-for-demo"
  vpc_security_group_ids = [aws_security_group.main.id]

}

resource "aws_security_group" "main" {
  egress =  [
      {
        cidr_blocks      = ["0.0.0.0/0", ]
        description      = ""
        from_port        = 0
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "-1"
        security_groups  = []
        self             = false
        to_port          = 0
      }
    ]

  ingress = [
      {
        cidr_blocks      = ["0.0.0.0/0", ]
        description      = ""
        from_port        = 22
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = false
        to_port          = 22
      }
    ]
}

resource "aws_key_pair" "deployer" {
    key_name    = "key-for-demo"
    public_key = file(var.ssh_pubkey_file)
}