#!/usr/bin/env bash

# Get the directory where this script is located
SYNC_CODES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    BRAVE SYNC CODES                           ║"
echo "╠════════════════════════════════════════════════════════════════╣"

if [[ ! -d $SYNC_CODES_DIR ]]; then
	echo "║ ❌ Sync codes directory not found: $SYNC_CODES_DIR"
	echo "╚════════════════════════════════════════════════════════════════╝"
	exit 1
fi

# Get the 25th word
the25th_word=""
if [[ -x "$SYNC_CODES_DIR/get_25th_word.sh" ]]; then
	the25th_word=$("$SYNC_CODES_DIR/get_25th_word.sh")
else
	echo "║ ⚠️  Warning: get_25th_word.sh not found or not executable"
	the25th_word="[25th word unavailable]"
fi

found_codes=false

for sync_file in "$SYNC_CODES_DIR"/brave_*; do
	if [[ -f $sync_file ]]; then
		found_codes=true
		filename=$(basename "$sync_file")
		# Extract username by removing the "brave_" prefix
		user="${filename#brave_}"
		sync_code_24_words=$(cat "$sync_file")

		# Combine the 24-word sync code with the 25th word
		full_sync_code="$sync_code_24_words $the25th_word"

		echo "║ $user:"
		echo "║ $full_sync_code"
		echo "║"
	fi
done

if [[ $found_codes == false ]]; then
	echo "║ ❌ No sync codes found in $SYNC_CODES_DIR"
	echo "║    Make sure your SOPS secrets are properly configured and deployed."
fi

echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "To use a sync code in Brave:"
echo "1. Open Brave browser"
echo "2. Go to Settings → Sync (or brave://settings/braveSync)"
echo "3. Click 'I have a sync code'"
echo "4. Enter the complete sync code from above"
echo "5. Choose what data to sync"
