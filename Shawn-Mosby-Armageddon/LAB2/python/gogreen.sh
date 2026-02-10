#!/usr/bin/env bash
set -e

# 1. Load variables
if [ -f lab2.env ]; then
    source lab2.env
    echo "[INFO] Loaded lab2.env"
else
    echo "[ERROR] lab2.env not found!"
    exit 1
fi

# 2. Run the ALB Connectivity Gate
echo "--- Running ALB Gate ---"
chmod +x run_all_gates_lab2b_alb.sh
./run_all_gates_lab2b_alb.sh

# 3. Run the General Gate
echo "--- Running General Gate ---"
chmod +x run_all_gates.sh
./run_all_gates.sh

# 4. Collect IR Evidence (The Malgus Gate)
echo "--- Collecting IR Evidence ---"
python3 malgus_cli.py collect-evidence \
  --secret-id "$SECRET_ID" \
  --ssm-path "$SSM_PATH" \
  --app-log-group "/aws/ec2/chewbacca-app" \
  --waf-log-group "aws-waf-logs-chewbacca" \
  --out "evidence.json"

echo "[SUCCESS] All gates processed. Check badge.txt and evidence.json."