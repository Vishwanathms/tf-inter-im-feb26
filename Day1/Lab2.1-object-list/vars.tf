variable "web_server_config" {
  description = "Configuration for the server"
  
  type = object({
    name          = string
    instance_type = string
    volume_size   = number
    #tags          = map(string)
  })

  default = {
    name          = "web-server"
    instance_type = "t3.micro"
    volume_size   = 20
    # tags = {
    #   Environment = "Dev"
    #   Owner       = "PlatformTeam"
    # }
  }
}


variable "db_server_config" {
  description = "Configuration for the server"
  
  default = [ 
    "db-server", "t3.medium",  20
  ]
}