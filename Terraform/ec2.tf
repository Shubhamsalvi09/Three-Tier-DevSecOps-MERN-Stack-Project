resource "aws_key_pair" "mykey" {
        key_name = "Terraform-Key"
        public_key = file("/home/shubhamsalvi/.ssh/id_ed25519.pub")
}

resource "aws_instance" "myec2" {
        ami = "ami-01a00762f46d584a1"
        instance_type = "t3.micro"
	key_name = aws_key_pair.mykey.key_name
        tags = {
                Name = "Jenkins-Master"
}
}

