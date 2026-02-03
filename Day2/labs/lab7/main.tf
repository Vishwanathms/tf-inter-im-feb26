provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "demo" {
  count = 1
  ami           = "ami-0532be01f26a3de55" # Amazon Linux 3 (example)
  instance_type = "t2.micro"
  key_name = "key1-vishwa"

  tags = {
    Name = local.name
  }
}

resource "aws_instance" "python_vm" {
  ami           = "ami-0030e4319cbf4dbf2" # Amazon Linux 3 (example)
  instance_type = "t3.micro"
  key_name = "key1-vishwa"

  tags = {
    Name = local.name
  }
}

locals {
  name =  format("%s-wed-%s-%02d", var.project, var.env,18)  
}

resource "null_resource" "local_exe" {

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p outputs
      cat > outputs/demo_private_ips.txt <<'EOF'
${join("\n", aws_instance.demo[*].private_ip)}
EOF
    EOT
  }
}


resource "null_resource" "cp-file" {

  triggers = {
    always_run = timestamp()
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    host = aws_instance.demo[0].public_ip
    private_key = file("key1-vishwa.pem")
  }

  provisioner "file" {
    source = "sample_file.sh"
    destination = "/home/ec2-user/sample_file.sh"
  }

}

resource "null_resource" "run_script" {

  triggers = {
    always_run = timestamp()
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    host = aws_instance.demo[0].public_ip
    private_key = file("key1-vishwa.pem")
  }

  provisioner "remote-exec" {
    inline = [ 
      "chmod +x /home/ec2-user/sample_file.sh",
      "sh sample_file.sh"
     ]
  }

  depends_on = [ null_resource.cp-file ]

}
