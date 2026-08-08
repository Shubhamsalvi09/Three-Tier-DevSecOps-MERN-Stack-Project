resource "aws_ecr_repository" "backend" {
  name = "mern-backend"
}

resource "aws_ecr_repository" "frontend" {
  name = "mern-frontend"
}
