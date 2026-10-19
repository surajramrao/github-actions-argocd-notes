#!/usr/bin/env bash

set -u

REPO="/mnt/c/Users/Neha Atkari/Downloads/GA-notes"
INTERVAL=30

cd "$REPO" || exit 1

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: Not a Git repository: $REPO"
    exit 1
fi

echo "Auto-push started: $REPO"
echo "Checking every ${INTERVAL} seconds."

while true; do
    # Avoid interfering with changes staged manually by the user.
    if ! git diff --cached --quiet; then
        echo "WARNING: Staged changes exist. Resolve them manually."
        sleep "$INTERVAL"
        continue
    fi

    if [[ -n "$(git status --porcelain)" ]]; then
        git add -A

        # Block common AWS keys, GitHub tokens, and private-key headers.
        if git diff --cached --unified=0 |
           grep -Eq \
           '(AKIA|ASIA)[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9_]{20,}|AWS_SECRET_ACCESS_KEY[[:space:]]*=[[:space:]]*[^<[:space:]]+'; then
            echo "ERROR: Possible secret detected. Commit blocked."
            git reset
            sleep "$INTERVAL"
            continue
        fi

        if git diff --cached --quiet; then
            sleep "$INTERVAL"
            continue
        fi

        if git -c user.name="suraj" \
               -c user.email="surajatkari11@gmail.com" \
               commit -m "Auto update: $(date '+%Y-%m-%d %H:%M:%S')"; then
            echo "Commit created."
        else
            echo "ERROR: Commit failed."
            sleep "$INTERVAL"
            continue
        fi
    fi

    # Push existing pending commits, including after a prior failure.
    if ! git push origin main; then
        echo "WARNING: Push failed. Will retry."
    else
        echo "Push successful."
    fi

    sleep "$INTERVAL"
done
