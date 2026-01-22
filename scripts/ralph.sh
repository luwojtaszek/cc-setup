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
  temp_output=$(mktemp)

  claude --permission-mode acceptEdits \
      -p "$prompt" \
      --output-format=stream-json \
      --include-partial-messages \
      --verbose \
      | tee "$temp_output" \
      | bunx repomirror visualize

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
