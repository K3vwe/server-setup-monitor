🚀 Automated Server Setup & Log Monitoring with Alerts

## 📌 Overview

This project is a Bash based automated solution for:
 - Server Setup: Automatically install essential packages, configure system settings, firewall and security and prepare the linux server for deployment
 - Log File Monitoring and Alerts: Continuously watches log files for errors or patterns, and ssend real-time alerts via emails or slack

## Scope
 This is a lightweight Devops project that demostrate Infrastructure automation, observability and alerting - critical skills for modern system administration and DevOps engineering.

✨ Features
  🔧 Automated Server Setup
   - Install Core utilities and security packages
   - Configure firewall rules (UFW)
   - Create Users amd manage permissions
   - Optional Nginx setup for web development
   
   📡 Log Monitoring and Alerts
   - Monitor multiple log files simultaneously
   - Detect multiple custom error pattern ('ERROR', 'CRITICAL', 'WARN')
   - Send alerts via:
     - 📧 Email (MSMTP/Sendmail)
     - 💬 Slack Webhooks
   - Maintain an audit log (alert.log)

   Customization
    - Configure log path and patterns in one file
    - Parameterize scripts for flexible usage
    - Works on most Linux Distro

🛠️ Requirements
  - Linux server (Ubuntu/Debian/CentOS recommended)
  - Bash 4.0+
  - grep, awk, tail, sed (default Linux tools)
  - msmtp or sendmail for email alerts
  - Slack webhook URL (optional, for Slack alerts)  

📥 Installation
 - Clone the repository
  git clone https://github.com/yourusername/server-setup-monitor.git
  cd server-setup-monitor

  - Make the script executable 
    chmod +x setup_server.sh monitor_logs.sh

  - Run the setup script
    ./setup_server.sh
  This installs dependencies, sets up firewall rules, creates users, and prepares the server environment.

▶️ Usage 
 - Start Monitoring Logs
  Edit config.conf file to define:
  - log files to monitor
  - Error pattern to catch 
  - Notification Method (Email/Slack)

  Then run;
  ./monitor_logs.sh

## Example Config (config.conf)
    # Log files to monitor
    LOG_FILES=("/var/log/syslog" "/var/log/auth.log")

    # Patterns to detect
    PATTERNS=("ERROR" "CRITICAL" "FAILED")

    # Alerting method
    ALERT_METHOD="slack"   # options: email | slack
    EMAIL="admin@example.com"
    SLACK_WEBHOOK="https://hooks.slack.com/services/XXXX/XXXX/XXXX"

📊 Example Output
 - Log entry detected:
  [2025-09-07 12:30:11] CRITICAL: Authentication failed for user root
 - Alert sent:
   - Email subject: [ALERT] CRITICAL issue detected
   - Slack Message: 
    🚨 CRITICAL issue detected in /var/log/auth.log
    Line: Authentication failed for user root

📐 Architecture
flowchart TD
    A[Log File(s)] -->|tail -F| B[Log Monitor Script]
    B -->|Pattern Match (grep/awk)| C{Alert?}
    C -->|Yes| D[Alert Dispatcher]
    D --> E[Slack Notification]
    D --> F[Email Notification]
    C -->|No| G[Continue Monitoring]

🚀 Roadmap (Future Improvements)
 - Add Docker support for containerized monitoring
 - Add support for Microsoft Teams / Discord alerts
 - Integrate with AWS CloudWatch for cloud-scale monitoring
 - Add unit tests for scripts

 🤝 Contributing
  Pull requests are welcome! Please open an issue first to discuss any major changes.

📜 License
  This project is licensed under the MIT License. See the LICENSE file for details.

👨‍💻 Author
    Onowho Victor
    🌐 GitHub: @yourusername
    💼 LinkedIn: Your LinkedIn