#!/usr/bin/env bash
# Installer for Bash Screensavers (caffesaver)

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="caffesaver"
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
MAIN_SCRIPT="$REPO_DIR/screensaver.sh"

if [[ ! -f "$MAIN_SCRIPT" ]]; then
  echo "Error: screensaver.sh not found in $REPO_DIR"
  exit 1
fi

echo "Installing $SCRIPT_NAME..."

# Check sudo access if needed
if [[ ! -w "$INSTALL_DIR" ]]; then
  echo "Needs permission to write to $INSTALL_DIR. Please run with sudo or allow access."
  echo "Try: sudo ./install.sh"
  exit 1
fi

# Create symlink
# Resolve relative path for symlink if needed, but absolute path is safer
ln -sf "$MAIN_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"

if [[ $? -eq 0 ]]; then
  echo "Success! You can now run '$SCRIPT_NAME' from anywhere."
  echo "Try: $SCRIPT_NAME -d -m matrix"
else
  echo "Failed to create symlink."
  exit 1
fi
