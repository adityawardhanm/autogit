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

        # Send email
        SUBJECT="Git Auto Push: $REPO ($BRANCH)"
        BODY=$(tail -n 20 "$LOGFILE")

        msmtp adityawardhanm@gmail.com <<EOF
To: youremail@example.com
From: bot@example.com
Subject: $SUBJECT

Git push completed successfully.

Repository	  : $REPO
Branch		    : $BRANCH
Activity Log	:
$BODY

— BOT
EOF

    fi    
    echo "--------------------------------------" >> "$LOGFILE"
done
