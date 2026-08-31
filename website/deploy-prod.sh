#!/usr/bin/env bash
# Deploy the website to Cloud Run PRODUCTION on myrecibook-prod.
# Wrapper over deploy-staging.sh — docs/prod-gcp-setup.md slice 1, step 4.
exec env PROJECT_ID=myrecibook-prod SERVICE=myrecibook-website "$(cd "$(dirname "$0")" && pwd)/deploy-staging.sh"
