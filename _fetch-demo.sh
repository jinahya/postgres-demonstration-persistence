#!/bin/sh
#
# Fetches the demonstration database dump into ./docker-entrypoint-initdb.d, where the postgres image
# loads it from on first start (see compose.yaml). Nothing it writes is tracked: even the smallest
# edition is 139 MB compressed and about 1.3 GB once loaded, so the dump is fetched, not committed.
#
#   https://postgrespro.com/community/demodb        (MIT; Postgres Professional)
#
# Idempotent: a complete download is left alone, a partial one is resumed. The file is kept as the
# .sql.gz the site serves, unchanged -- the image's entrypoint runs *.sql.gz through `gunzip -c | psql`
# itself, so the ~430 MB plain file never has to exist on disk.
#
#   DEMO_VERSION   the snapshot date in the file name; 20250901 is the current (01.09.2025) release
#   DEMO_EDITION   3m (three months of flights, the smallest), 6m, 1y or 2y
#
# From here the server delivers about 100 KB/s, so the first fetch of the 3m edition takes ~20 minutes.
set -eu

cd "$(dirname "$0")"

DEMO_VERSION="${DEMO_VERSION:-20250901}"
DEMO_EDITION="${DEMO_EDITION:-3m}"

name="demo-${DEMO_VERSION}-${DEMO_EDITION}.sql.gz"
url="https://edu.postgrespro.ru/${name}"
# kept under the site's own name, so a file downloaded by hand into the directory counts just the same;
# the entrypoint runs the directory sorted by name, and 00-create-database-demo.sql sorts before demo-*
target="docker-entrypoint-initdb.d/${name}"

if [ -f "${target}" ]; then
    echo "==> ${target} is already here; delete it to fetch again"
    exit 0
fi

# any other edition left from a previous run would be loaded too, as a second DROP/CREATE of `demo`
for other in docker-entrypoint-initdb.d/demo-*.sql.gz; do
    if [ -f "${other}" ]; then
        echo "==> removing ${other}, which would be loaded alongside ${target}"
        rm -f "${other}"
    fi
done

echo "==> fetching ${url}"
echo "    to ${target}"
# -C -: resume a .part a previous, interrupted run left behind; --fail: an HTTP error is an error,
# not a saved HTML page; the final mv is what makes the file visible as complete
curl --fail --location --continue-at - --progress-bar --output "${target}.part" "${url}"
gzip -t "${target}.part"
mv "${target}.part" "${target}"

echo "==> done: $(wc -c < "${target}" | tr -d ' ') bytes"
