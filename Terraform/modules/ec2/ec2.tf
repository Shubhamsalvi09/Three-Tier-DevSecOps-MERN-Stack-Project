resource "aws_key_pair" "mykey" {
        key_name = "id_ed25519"
        public_key = file("/home/shubhamsalvi/.ssh/id_ed25519.pub")
}

resource "aws_instance" "myec2" {
        ami = "ami-006f82a1d5a27da54"
        instance_type = "m7i-flex.large"
	key_name = aws_key_pair.mykey.key_name
        tags = {
                Name = "Master"
}
}

