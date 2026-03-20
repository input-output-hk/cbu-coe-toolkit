#!/usr/bin/env bash
# AAMM Full Data Collector
# Usage: ./collect-all.sh owner/repo [output_dir]
# Runs both readiness and adoption collection in sequence.

set -euo pipefail

REPO="${1:?Usage: $0 owner/repo [output_dir]}"
OUTDIR="${2:-/tmp/aamm-$(echo "$REPO" | tr '/' '-')}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== AAMM Full Collection: $REPO ==="
echo ""

"$SCRIPT_DIR/collect-readiness.sh" "$REPO" "$OUTDIR"
echo ""
echo "---"
echo ""
"$SCRIPT_DIR/collect-adoption.sh" "$REPO" "$OUTDIR"

echo ""
echo "=== Full collection complete ==="
echo "Output: $OUTDIR"
echo "Total files: $(ls "$OUTDIR" "$OUTDIR/adoption/" 2>/dev/null | wc -l)"
