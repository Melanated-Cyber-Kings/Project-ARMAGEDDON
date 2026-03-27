Lab 3: Automated Infrastructure & Evidence Sync
Objective: Deploy multi-region infrastructure and automate evidence collection using GitHub Webhooks and Jenkins.

What I Accomplished:

Webhook Automation: Configured a GitHub Webhook to trigger Jenkins builds on every push to the Cameron-Cleveland-Armageddon-Branch.

Infrastructure as Code: Used Terraform to deploy a Transit Gateway Attachment in Tokyo and initialized the Sao Paulo environment.

Automated Evidence Sync: Updated the Jenkins Pipeline with a post-success hook that automatically syncs the Armageddon Project Evidence/ folder to the S3 Bucket.

Permission Workaround: Since I am working in an Org repo without Admin settings access, I verified the Webhook via Jenkins "Started by GitHub push" logs and automated S3 uploads.
