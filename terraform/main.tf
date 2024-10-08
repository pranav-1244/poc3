provider "aws" {
  region = "us-east-1"  # Replace with your preferred region
}

# Security Group for EC2 instance allowing necessary ports
resource "aws_security_group" "docker_sg" {
  name        = "docker_sg_1212"
  description = "Allow SSH, HTTP, Jenkins, and SonarQube traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic for Apache2
  }
 
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Jenkins traffic on port 8080
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SonarQube traffic on port 9000
  }

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
  key_name      = "poc3"  # Replace with your AWS key pair
  vpc_security_group_ids = [aws_security_group.docker_sg.id]

  tags = {
    Name = "Docker-Jenkins-SonarQube-Apache2"
  }
}

# Create the dynamic inventory file on your local machine with the public IP of the instance
resource "local_file" "inventory_ini" {
  depends_on = [aws_instance.docker_instance]  # Ensure EC2 instance is created before generating the file
  content = <<EOT
[server]
server ansible_host=${aws_instance.docker_instance.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/pranav1244/poc3/terraform/poc3.pem
EOT
  filename = "/home/pranav1244/poc3/playbook/inventory.ini"  # Local path where inventory file will be saved
}

# Null resource to run the Ansible playbooks for Jenkins and SonarQube using the inventory file
resource "null_resource" "run_ansible_playbooks" {
  depends_on = [local_file.inventory_ini]  # Ensure the inventory file is created before running the playbooks

  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds...'; sleep 30; ansible-playbook -i /home/pranav1244/poc3/playbook/inventory.ini --private-key /home/pranav1244/poc3/terraform/poc3.pem -u ubuntu --ssh-extra-args='-o StrictHostKeyChecking=no' /home/pranav1244/poc3/ansible-playbook/sonarqube.yml"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i /home/pranav1244/poc3/playbook/inventory.ini --private-key /home/pranav1244/poc3/terraform/poc3.pem -u ubuntu --ssh-extra-args='-o StrictHostKeyChecking=no' /home/pranav1244/poc3/ansible-playbook/jenkins.yml"
  }
}

# Output the public IP of the instance
output "instance_public_ip" {
  value = aws_instance.docker_instance.public_ip
}
