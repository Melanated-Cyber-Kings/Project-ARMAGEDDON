# Tokyo-Specific Launch Template
resource "aws_launch_template" "shinjuku_lt" {
  name_prefix   = "shinjuku-lt-"
  image_id      = "ami-0d52744d6551d851e" # Example Amazon Linux 2023 ID for ap-northeast-1
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.shinjuku_ec2_sg.id]
 user_data = base64encode(<<-EOF
              #!/bin/bash
              cat << 'APP' > /root/app.py
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import socket

class MedicalVaultHandler(BaseHTTPRequestHandler):
    def check_rds(self):
        rds_endpoint = "${aws_db_instance.shinjuku_medical_db.address}" 
        port = 3306
        try:
            with socket.create_connection((rds_endpoint, port), timeout=2):
                return "CONNECTED"
        except Exception as e:
            return f"FAILED: {str(e)}"

    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        db_status = self.check_rds()
        
        response = {
            "status": "Success", 
            "region": "Tokyo-Hub", 
            "database_connectivity": db_status,
            "note": "Verified via TGW to Tokyo RDS"
        }
        self.wfile.write(json.dumps(response).encode())

server = HTTPServer(('0.0.0.0', 80), MedicalVaultHandler)
server.serve_forever()
APP

              nohup python3 /root/app.py > /root/app.log 2>&1 &
              EOF
)

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "shinjuku-medical-node" }
  }
}

# Tokyo-Specific ASG
resource "aws_autoscaling_group" "shinjuku_asg" {
  desired_capacity = 2
  max_size         = 4
  min_size         = 1
  # Pointing to Tokyo Subnets
  vpc_zone_identifier = [aws_subnet.chewbacca_private_subnet01.id, aws_subnet.chewbacca_private_subnet02.id]
  target_group_arns   = [aws_lb_target_group.shinjuku_tg.arn]
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.shinjuku_lt.id
    version = "$Latest"
  }
}
