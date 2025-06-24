#!/usr/bin/env bash
# mds2hdcatap.sh – convert NFDI4Health-MDS to Health DCAT-AP (JSON-LD)
# Requires: jq ≥ 1.6
#
# Example:
#   ./mds2hdcatap.sh --data study-mds.json --config config.json > study-hdcat.jsonld

set -euo pipefail

DATA=""
CONFIG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--data)   DATA="$2";    shift 2 ;;
    --data=*)    DATA="${1#*=}"; shift ;;
    -c|--config) CONFIG="$2";  shift 2 ;;
    --config=*)  CONFIG="${1#*=}"; shift ;;
    -h|--help)
      echo "Usage: $(basename "$0") --data [MDS JSON data file] --config [JSON config file] > out.jsonld"
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$DATA" || -z "$CONFIG" ]] && { echo "Both --data and --config are required." >&2; exit 1; }

jq -n \
   --slurpfile mds "$DATA" \
   --slurpfile cfg "$CONFIG" \
   -f transform.jq
