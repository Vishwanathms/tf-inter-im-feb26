# This resource is using object

resource "aws_instance" "web_01" {
  ami           = "ami-12345678"
  instance_type = var.web_server_config.instance_type

  root_block_device {
    volume_size = var.web_server_config.volume_size
  }

  tags = merge(
    var.server_config.tags,
    {
      Name = var.web_server_config.name
    }
  )
}

# This resource is using list

resource "aws_instance" "db_01" {
  ami           = "ami-12345678"
  instance_type = var.db_server_config[1]

  root_block_device {
    volume_size = var.db_server_config[2]
  }

  tags = merge(
    var.server_config.tags,
    {
      Name = var.db_server_config[0]
    }
  )
}