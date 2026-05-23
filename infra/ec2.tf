# SSH Key
resource "aws_key_pair" "iii_key" {
  key_name   = "iii-key-new"
  public_key = file("yes.pub")
}

# 1. API Gateway VM (Public Subnet)
resource "aws_instance" "api_gateway" {
  ami                    = "ami-03f4878755434977f" # Verified Ubuntu 22.04 LTS for ap-south-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.api_gw.id]
  key_name               = aws_key_pair.iii_key.key_name
  tags                   = { Name = "api-gateway" }
}

# 2. Central Engine (Private Subnet)
resource "aws_instance" "engine" {
  ami                    = "ami-03f4878755434977f" # Verified Ubuntu 22.04 LTS for ap-south-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = aws_key_pair.iii_key.key_name
  private_ip             = "10.0.2.10"
  tags                   = { Name = "iii-engine" }
}

# 3. Inference Worker (Private Subnet)
resource "aws_instance" "inference_worker" {
  ami                    = "ami-03f4878755434977f" # Verified Ubuntu 22.04 LTS for ap-south-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = aws_key_pair.iii_key.key_name
  private_ip             = "10.0.2.20"
  tags                   = { Name = "inference-worker" }
}

# 4. Caller Worker (Private Subnet)
resource "aws_instance" "caller_worker" {
  ami                    = "ami-03f4878755434977f" # Verified Ubuntu 22.04 LTS for ap-south-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = aws_key_pair.iii_key.key_name
  private_ip             = "10.0.2.30"
  tags                   = { Name = "caller-worker" }
}
