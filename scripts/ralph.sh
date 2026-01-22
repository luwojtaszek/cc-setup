# ralph.sh
# Usage: ./ralph.sh <iterations> <prompt-file>

set -e

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <iterations> <prompt-file>"
  exit 1
fi

if [ ! -f "$2" ] || [ ! -r "$2" ]; then
  echo "Error: Prompt file '$2' does not exist or is not readable"
  exit 1
fi

prompt=$(cat "$2")

# For each iteration, run Claude Code with the prompt from the file.
for ((i=1; i<=$1; i++)); do
  result=$(claude --permission-mode acceptEdits -p "$prompt")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete, exiting."
    exit 0
  fi
done
