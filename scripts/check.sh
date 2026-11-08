#!/bin/sh
# Compile the template for US Letter and A4 and the README example, with the network blocked.
# This checkout is served as @preview/dialtone-fax from a temporary package path, so nothing is left
# behind in the local package directory.
# Usage: scripts/check.sh   (needs typst on PATH and Ghostscript for the page size check)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
version=$(sed -n 's/^version = "\(.*\)"/\1/p' "$root/typst.toml")

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/cache" "$work/packages/preview/dialtone-fax"
ln -s "$root" "$work/packages/preview/dialtone-fax/$version"
pkg="--package-path $work/packages --package-cache-path $work/cache"
# A dead proxy makes any download fail, and an empty cache shows none was needed.
export HTTPS_PROXY=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 https_proxy=http://127.0.0.1:9
cd "$work"
typst init $pkg "@preview/dialtone-fax:$version" proj >/dev/null 2>&1
cd proj
sed 's/paper: "us-letter"/paper: "a4"/' main.typ > a4.typ
sed -n '/^```typ$/,/^```$/p' "$root/README.md" | sed '1d;$d' > readme.typ
for f in main a4 readme; do
  typst compile $pkg "$f.typ" "$f.pdf"
  box=$(gs -q -dNODISPLAY -dNOSAFER -c "($f.pdf) (r) file runpdfbegin 1 pdfgetpage /MediaBox pget pop == quit")
  echo "$f.typ compiled, page 1 MediaBox $box"
done
test -z "$(ls -A "$work/cache")" && echo "no package was downloaded"
