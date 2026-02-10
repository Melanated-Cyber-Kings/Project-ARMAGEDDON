resource "aws_autoscaling_group" "liberdade_asg" {
  provider            = aws.saopaulo
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.liberdade_private_subnet01.id, aws_subnet.liberdade_private_subnet02.id]
  target_group_arns   = [aws_lb_target_group.liberdade_tg.arn]
  health_check_type   = "ELB"


  launch_template {
    id      = aws_launch_template.liberdade_lt.id
    version = "$Latest"
  }

}

resource "aws_launch_template" "liberdade_lt" {
  provider      = aws.saopaulo
  name_prefix   = "liberdade-lt-"
  image_id      = "ami-0af6e9042ea5a4e3e" # Example Amazon Linux 2023 in sa-east-1
  instance_type = "t3.micro"

  iam_instance_profile { #needed for ssm for CLI checks
    name = aws_iam_instance_profile.ssm_profile.name
  }


  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.liberdade_ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # 1. Create the app using ONLY built-in Python libraries
              # This bypasses the need for an internet connection/NAT Gateway
              cat << 'APP' > /root/app.py
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class MedicalVaultHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        # This proves the node is up even without Flask installed
        response = {"status": "Success", "region": "Sao-Paulo-Spoke", "mode": "Secondary-Vault"}
        self.wfile.write(json.dumps(response).encode())

    def do_POST(self):
        # This mimics the /records/save/ behavior for your Lab
        self.send_response(201)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {"status": "Record Saved", "vault": "Liberdade-01"}
        self.wfile.write(json.dumps(response).encode())

# Start the server on Port 80
def run():
    server_address = ('0.0.0.0', 80)
    httpd = HTTPServer(server_address, MedicalVaultHandler)
    print("Private Vault API running on port 80...")
    httpd.serve_forever()

if __name__ == '__main__':
    run()
APP

              # 2. Start the app as root in the background
              # Using the built-in python3 (which comes with Ubuntu 22.04)
              nohup python3 /root/app.py > /root/app.log 2>&1 &
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "liberdade-medical-node" }
  }
}