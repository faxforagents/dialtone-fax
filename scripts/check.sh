#!/bin/sh
# Compile the template for US Letter and A4 and the README example, with the network blocked.
# Links this checkout as @preview/dialtone-fax:0.1.0 in the local package directory first.
# Usage: scripts/check.sh   (needs typst on PATH and Ghostscript for the page size check)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
version=$(sed -n 's/^version = "\(.*\)"/\1/p' "$root/typst.toml")
data=${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/preview/dialtone-fax
mkdir -p "$data"
ln -sfn "$root" "$data/$version"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/cache"
# A dead proxy makes any download fail, and an empty cache shows none was needed.
export HTTPS_PROXY=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 https_proxy=http://127.0.0.1:9
cd "$work"
typst init "@preview/dialtone-fax:$version" proj >/dev/null
cd proj
sed 's/paper: "us-letter"/paper: "a4"/' main.typ > a4.typ
sed -n '/^```typ$/,/^```$/p' "$root/README.md" | sed '1d;$d' > readme.typ
for f in main a4 readme; do
  typst compile --package-cache-path "$work/cache" "$f.typ" "$f.pdf"
  box=$(gs -q -dNODISPLAY -dNOSAFER -c "($f.pdf) (r) file runpdfbegin 1 pdfgetpage /MediaBox pget pop == quit")
  echo "$f.typ compiled, page 1 MediaBox $box"
done
test -z "$(ls -A "$work/cache")" && echo "no package was downloaded"
