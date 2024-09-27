provider "aws" {
  region = "us-east-1"  # Replace with your preferred region
}
# Security Group for EC2 instance allowing necessary ports
resource "aws_security_group" "docker_sg" {
  name        = "docker_sg_85"
  description = "Allow SSH, HTTP, Jenkins, and SonarQube traffic"
  # Allow SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (restrict to your IP in production)
  }
  # Allow HTTP traffic (port 80) for Apache2
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic for Apache2
  }
  # Allow Jenkins (port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Jenkins traffic on port 8080
  }
  # Allow SonarQube (port 9000)
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SonarQube traffic on port 9000
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Launch an EC2 instance with a custom AMI (Docker pre-installed)
resource "aws_instance" "docker_instance" {
  ami           = "ami-0a412b2eaeea72443"  # Replace with your custom AMI ID
  instance_type = "t2.medium"
  key_name      = "poc3"           # Replace with your AWS key pair
  vpc_security_group_ids = [aws_security_group.docker_sg.id]
  tags = {
    Name = "Docker-Jenkins-SonarQube-Apache2"
  }
  # Wait until the instance is accessible via SSH
  provisioner "remote-exec" {
    inline = [
      "echo Waiting for instance to be accessible...",
      "sleep 10",  # Adding a delay to ensure the instance is ready
      "echo Instance should now be accessible via SSH."
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/pranav1244/poc3/terraform/poc3.pem")  # Ensure this path is correct in WSL
      host        = self.public_ip
    }
  }
  # Trigger Ansible playbook after instance creation with StrictHostKeyChecking disabled
  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.public_ip}, --private-key /home/pranav1244/poc3/terraform/poc3.pem -u ubuntu --ssh-extra-args='-o StrictHostKeyChecking=no' /home/pranav1244/poc3/ansible-playbook/jenkins.yml"
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.public_ip}, --private-key /home/pranav1244/poc3/terraform/poc3.pem -u ubuntu --ssh-extra-args='-o StrictHostKeyChecking=no' /home/pranav1244/poc3/ansible-playbook/sonarqube.yml"
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.public_ip}, --private-key /home/pranav1244/poc3/terraform/poc3.pem -u ubuntu --ssh-extra-args='-o StrictHostKeyChecking=no' /home/pranav1244/poc3/ansible-playbook/pipeline.yml"
  }
}
# Output the public IP of the instance
output "instance_public_ip" {
  value = aws_instance.docker_instance.public_ip
}