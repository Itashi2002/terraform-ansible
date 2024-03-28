resource "aws_instance" "ansibleController" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    Name = var.name
  }
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [
    aws_security_group.ansibleController.id
  ]
}
resource "null_resource" "copyAnsibleCfg" {
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    source = "ansible.cfg"
    destination = "./ansible.cfg"
  }
}
resource "null_resource" "copyPrivateKey" {
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    destination = "/home/ubuntu/.ssh/id_rsa"
    content = tls_private_key.keypair.private_key_pem
  }
}
resource "null_resource" "installAnsible" {
  depends_on = [ 
    null_resource.copyPrivateKey 
  ]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.ansibleController.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.keypair.private_key_pem
    }
    inline = [
      "sudo apt-get update -y && sudo apt-get install -y ansible",
      "echo ${aws_instance.ansibleController.private_ip} > selfManagedNode",
      "chmod 600 ~/.ssh/id_rsa",
      "ansible --version",
      "ansible all -m ping"
    ]
  }
}

