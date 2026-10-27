#!/usr/bin/env bash
# Prints a --dart-define-from-file JSON containing only the variables that are set,
# so empty secrets don't override the in-code defaults.
set -euo pipefail

keys=(GROQ_API_KEY RAZORPAY_KEY_ID STREAM_API_KEY)
args=()
for k in "${keys[@]}"; do
  if [ -n "${!k:-}" ]; then
    args+=(--arg "$k" "${!k}")
  fi
done

jq -n '$ARGS.named' "${args[@]}"
