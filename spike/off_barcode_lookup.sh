#!/usr/bin/env bash
# OFF coverage spike — does Open Food Facts know the products in OUR kitchen?
# Fill BARCODES with ~10 numbers off the shelf (the digits printed under the
# barcode — no scanner needed), then: bash spikes/off_barcode_lookup.sh
# Reading the result: misses = what the label-photo fallback must carry.

BARCODES=(
  7038010071751   # first shelf item (Arnar, 2026-08-17)
  7090042651011
  7032069755402
  7027110111887
  196005242504
  8033406265775
  7070866013370
  7029121012269
  7039010599122
  7039010552585
  7311041024621
  7311041085844
  7039010087124
  7038010054488
  7340191156098
  # 3017620422003   # sanity check: Nutella, should always HIT
)

hits=0; total=0
for b in "${BARCODES[@]}"; do
  total=$((total+1))
  # A blank reply is usually OFF throttling us, not a missing product —
  # only "status":0 in the body is a real MISS. Anything else: back off, retry.
  for attempt in 1 2 3; do
    body=$(curl -s -A "MyReciBook-spike/0.1 (arnarvalurjonsson@gmail.com)" \
      "https://world.openfoodfacts.org/api/v2/product/$b.json?fields=product_name,brands,nutriments")
    name=$(printf '%s' "$body" | sed -n 's/.*"product_name":"\([^"]*\)".*/\1/p')
    [ -n "$name" ] && break
    case "$body" in *'"status":0'*) break ;; esac
    sleep $((attempt*5))
  done
  if [ -n "$name" ]; then
    hits=$((hits+1)); printf 'HIT   %s  %s\n' "$b" "$name"
  elif case "$body" in *'"status":0'*) false ;; *) true ;; esac; then
    printf 'ERR   %s  (throttled/network after 3 tries — rerun later, not a miss)\n' "$b"
  else
    printf 'MISS  %s\n' "$b"
  fi
  sleep 2   # OFF asks for gentle rate use
done
echo "----"
echo "$hits / $total found on Open Food Facts"
