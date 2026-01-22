# ralph.sh
# Usage: ./ralph.sh [--dangerous] <iterations> <prompt-file>

set -e

# Parse optional --dangerous flag
PERMISSION_MODE="--permission-mode acceptEdits"
if [ "$1" = "--dangerous" ]; then
  PERMISSION_MODE="--dangerously-skip-permissions"
  shift
fi

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 [--dangerous] <iterations> <prompt-file>"
  exit 1
fi

if [ ! -f "$2" ] || [ ! -r "$2" ]; then
  echo "Error: Prompt file '$2' does not exist or is not readable"
  exit 1
fi

prompt=$(cat "$2")

# For each iteration, run Claude Code with the prompt from the file.
for ((i=1; i<=$1; i++)); do
  temp_output=$(mktemp)

  claude $PERMISSION_MODE \
      -p "$prompt" \
      --output-format=stream-json \
      --include-partial-messages \
      --verbose \
      | tee "$temp_output" \
      | "$(dirname "$0")/visualize-stream.sh"

  # Push changes to git (current branch)
  git push

  # Check completion in captured output
  if grep -q "<promise>COMPLETE</promise>" "$temp_output"; then
    echo "Job complete, exiting."
    rm "$temp_output"
    exit 0
  fi

  rm "$temp_output"
  echo -e "\n\n========================LOOP ($i/$1)=========================\n\n"
done
