#!/usr/bin/env bash
set -euo pipefail

host="${INGRESS_HOST:-wordpress.lab.test}"
port="${INGRESS_PORT:-8086}"
address="${INGRESS_ADDRESS:-127.0.0.1}"
expected="${EXPECTED_TEXT:-Ingress routing verification}"

response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

if ! status="$(curl --noproxy '*' \
  --resolve "${host}:${port}:${address}" \
  --silent --show-error --location \
  --connect-timeout 5 --max-time 20 \
  --output "$response_file" \
  --write-out '%{http_code}' \
  "http://${host}:${port}/")"; then
  printf 'FAIL: HTTP request could not complete.\n' >&2
  exit 1
fi

if [[ "$status" != "200" ]]; then
  printf 'FAIL: expected HTTP 200, received %s.\n' "$status" >&2
  exit 1
fi

if ! grep -Fq -- "$expected" "$response_file"; then
  printf 'FAIL: expected application content was not found.\n' >&2
  exit 1
fi

printf 'PASS: HTTP 200 and expected application content found.\n'
