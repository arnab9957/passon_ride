#!/usr/bin/env bash
# Prints a --dart-define-from-file JSON containing only the variables that are set,
# so empty secrets don't override the in-code defaults.
set -euo pipefail

# Only public, client-safe values belong here. Server secrets (Groq, Razorpay secret,
# ImageKit private key) are Supabase function secrets and must never be added.
keys=(RAZORPAY_KEY_ID STREAM_API_KEY SENTRY_DSN)
args=()
for k in "${keys[@]}"; do
  if [ -n "${!k:-}" ]; then
    args+=(--arg "$k" "${!k}")
  fi
done

jq -n '$ARGS.named' "${args[@]}"
