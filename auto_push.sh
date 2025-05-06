#!/bin/bash

REPOS=(
	"/path/to/your/folder1"
 	"/path/to/your/folder2"
	"/path/to/your/folder3"
)

LOGFILE="/tmp/git_auto_push.log"
: > "$LOGFILE"  # Empty the log file at start

for REPO in "${REPOS[@]}"
do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing $REPO" >> "$LOGFILE"
    
    if [ ! -d "$REPO/.git" ]; then
        echo "Skipped: $REPO is not a Git repo" >> "$LOGFILE"
        continue
    fi

    cd "$REPO" || { echo "Failed to enter $REPO" >> "$LOGFILE"; continue; }

    if [[ -z $(git status --porcelain) ]]; then
        echo "No changes in $REPO" >> "$LOGFILE"
        continue
    fi

    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Failed to determine branch in $REPO" >> "$LOGFILE"
        continue
    fi

    git add . 2>>"$LOGFILE"
    if [ $? -ne 0 ]; then
        echo "git add failed in $REPO" >> "$LOGFILE"
        continue
    fi

    CHANGES=$(git diff --cached --stat)
    [[ -z "$CHANGES" ]] && CHANGES=$(git diff --stat)
    [[ -z "$CHANGES" ]] && CHANGES="Minor auto-commit (no diff available)"

    git commit -m "Auto-commit on '$BRANCH' at $(date '+%Y-%m-%d %H:%M:%S'):

$CHANGES" >> "$LOGFILE" 2>&1

    if [ $? -ne 0 ]; then
        echo "Commit failed in $REPO" >> "$LOGFILE"
        continue
    fi

    git push origin "$BRANCH" >> "$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        echo "[$MODE] Push failed in $REPO (check network/auth/branch)" >> "$LOGFILE"
    else
        echo " [$MODE] Pushed to $BRANCH successfully" >> "$LOGFILE"

        # Format the current date and time
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

        # Create a more descriptive subject line
        SUBJECT="Git Auto Push: $REPO ($BRANCH) - $(date "+%b %d, %Y")"

        # Get the last 20 lines of the log file for the activity summary
        BODY=$(tail -n 20 "$LOGFILE")

        # Get the commit count for this push (optional enhancement)
        COMMIT_COUNT=$(git rev-list --count HEAD ^origin/$BRANCH)

        # Send the email with improved formatting
        msmtp user@gmail.com <<EOF
To: user@gmail.com
From: bot@example.com
Subject: $SUBJECT
Content-Type: text/html; charset=UTF-8

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @media (prefers-color-scheme: dark) {
      body {
        background-color: #0d1117 !important;
        color: #e6edf3 !important;
      }
      .header {
        background-color: #161b22 !important;
        border-left: 4px solid #8957e5 !important;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3) !important;
      }
      .header h2 {
        color: #d2a8ff !important;
      }
      .log-section {
        background-color: #161b22 !important;
        color: #e6edf3 !important;
        border: 1px solid #30363d !important;
      }
      .log-section pre {
        color: #a5d6ff !important;
      }
      .footer {
        color: #8b949e !important;
        border-top: 1px solid #30363d !important;
      }
    }
  </style>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; max-width: 620px; margin: 0 auto; padding: 20px; color: #24292f; background-color: #f6f8fa;">
  <div class="header" style="background-color: #ffffff; padding: 20px; border-left: 4px solid #8957e5; margin-bottom: 24px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);">
    <h2 style="margin-top: 0; color: #6f42c1; font-size: 22px; font-weight: 600;">Git Push Completed Successfully</h2>
    <p style="margin: 8px 0; font-size: 15px;"><strong style="color: #24292f;">Repository:</strong> $REPO</p>
    <p style="margin: 8px 0; font-size: 15px;"><strong style="color: #24292f;">Branch:</strong> $BRANCH</p>
    <p style="margin: 8px 0; font-size: 15px;"><strong style="color: #24292f;">Time:</strong> $TIMESTAMP</p>
  </div>
  
  <div class="log-section" style="background-color: #ffffff; padding: 20px; border-radius: 8px; font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace; white-space: pre-wrap; margin-bottom: 24px; border: 1px solid #d0d7de; box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);">
    <h3 style="margin-top: 0; color: #6f42c1; font-size: 16px; font-weight: 600; margin-bottom: 12px;">Activity Log:</h3>
    <pre style="margin: 0; overflow-x: auto; color: #0550ae; line-height: 1.5; font-size: 13px;">$BODY</pre>
  </div>
  
  <p class="footer" style="color: #57606a; font-size: 13px; margin-top: 24px; padding-top: 12px; border-top: 1px solid #d0d7de; text-align: center;">
    — BOT<br>
    <em>Automated Git Notification Service</em>
  </p>
</body>
</html>
EOF

    fi    
    echo "--------------------------------------" >> "$LOGFILE"
done
