#!/bin/sh
set -e

CERT_DIR=$(mktemp -d)
KEY_FILE="$CERT_DIR/tls.key"
CRT_FILE="$CERT_DIR/tls.crt"
SECRET_NAME="msgb-tls"
NAMESPACE="${1:-default}"

openssl req -x509 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CRT_FILE" \
  -days 365 -nodes \
  -subj "/CN=msgb.test"

kubectl create secret tls "$SECRET_NAME" \
  --namespace "$NAMESPACE" \
  --key "$KEY_FILE" \
  --cert "$CRT_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

rm -rf "$CERT_DIR"

echo "Secret '$SECRET_NAME' created in namespace '$NAMESPACE'"
