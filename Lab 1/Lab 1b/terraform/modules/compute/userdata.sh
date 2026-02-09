#!/bin/bash
            set -e
            
            # Update and install (Ubuntu uses apt-get)
            apt-get update
            apt-get install -y python3 python3-pip nginx mysql-client
            
            # Install Flask
            pip3 install flask
            
            # Create simple Flask app
            mkdir -p /opt/simple-app
            cat > /opt/simple-app/app.py << 'PYEOF'
            from flask import Flask
            app = Flask(__name__)
            
            @app.route('/')
            def home():
                return "Lab 1B/2B App is Running!", 200
            
            @app.route('/health')
            def health():
                return "Healthy", 200
            
            if __name__ == '__main__':
                app.run(host='0.0.0.0', port=80)
            PYEOF
            
            # Create systemd service
            cat > /etc/systemd/system/simpleapp.service << 'SERVICEEOF'
            [Unit]
            Description=Simple Flask App for Lab 2B
            After=network.target
            
            [Service]
            WorkingDirectory=/opt/simple-app
            ExecStart=/usr/bin/python3 /opt/simple-app/app.py
            Restart=always
            User=root
            
            [Install]
            WantedBy=multi-user.target
            SERVICEEOF
            
            # Start the service
            systemctl daemon-reload
            systemctl enable simpleapp
            systemctl start simpleapp
            
            # Also start nginx as backup
            systemctl start nginx
            systemctl enable nginx
            
            echo "Setup complete!"
            EOF