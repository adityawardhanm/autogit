# autogit

**autogit** is a lightweight, automated Git commit scheduler that periodically commits changes to your local repositories and pushes them to their corresponding GitHub remotes. It also sends an email notification upon successful push.

---

## Features
- Automatically commits changes in multiple Git repositories  
- Customizable commit messages with timestamps and change summaries  
- Sends email notifications after successful push operations  
- Cron-friendly and easy to set up  

---

## Setup Instructions

### 1. Configure Repositories
Edit the script and replace the placeholder paths in the `REPOS` array with the absolute paths to your local Git repositories:

```bash
REPOS=(
  "/home/user/projects/repo1"
  "/home/user/projects/repo2"
  # Add more repositories as needed
)
```

Each repository should already be initialized with Git and connected to a remote (e.g., GitHub).

### 2. Make the Script Executable

```bash
chmod +x /home/user/scripts/auto_push.sh
```

### 3. Schedule with Cron
To run the script every day at 9:00 PM, add the following line to your crontab:

```bash
echo "0 21 * * * /home/user/scripts/auto_push.sh" | crontab -
```

You can customize the schedule using crontab.guru.

## Example Log Output

The script logs activity such as:
- Status of git add, commit, and push
- Repository and branch names
- Change summary
- Email delivery status

Logs are written to `/tmp/git_auto.log` by default and can be changed in the script.

## Email Notifications

This script uses msmtp to send email notifications after a successful push.
- Make sure msmtp is installed and configured (e.g., `~/.msmtprc`) for the sender email account.
- A sample .msmtprc entry might look like:

```ini
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           bot@gmail.com
user           bot@gmail.com
passwordeval   "gpg --quiet --for-your-eyes-only --no-tty -d ~/.gmail_password.gpg"

account default : gmail
```

## Contributions

Feel free to fork, improve, and contribute back — pull requests are welcome!
If you encounter any issues or want new features, feel free to open an issue.
