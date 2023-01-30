#!/bin/sh

# Script inspired by the commit-msg hook used in Gerrit Code Review
# This adds a trailer to the commit with the value of CODESPACE_NAME

set -u

# avoid [[ which is not POSIX sh.
if test "$#" != 1 ; then
  echo "$0 requires an argument."
  exit 1
fi

if test ! -f "$1" ; then
  echo "file does not exist: $1"
  exit 1
fi

# if $CODESPACE_NAME is not set then exit
if test -z "${CODESPACE_NAME:-}" ; then
  echo "not running in a codespace"
  exit 0
fi

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  refhash="$(git rev-parse HEAD)"
else
  refhash="$(git hash-object -t tree /dev/null)"
fi

random=$({ git var GIT_COMMITTER_IDENT ; echo "$refhash" ; cat "$1"; } | git hash-object --stdin)
dest="$1.tmp.${random}"

trap 'rm -f "$dest" "$dest-2"' EXIT

if ! git stripspace --strip-comments < "$1" > "${dest}" ; then
   echo "cannot strip comments from $1"
   exit 1
fi

if test ! -s "${dest}" ; then
  echo "file is empty: $1"
  exit 1
fi

token="Codespace"
value="$CODESPACE_NAME"
pattern=".*"

# If the trailer already exists, do nothing
if git interpret-trailers --parse < "$1" | grep -q "^$token: $pattern$" ; then
  exit 0
fi

# There must be a Signed-off-by trailer for the code below to work. Insert a
# sentinel at the end to make sure there is one.
# Avoid the --in-place option which only appeared in Git 2.8
if ! git interpret-trailers \
         --trailer "Signed-off-by: SENTINEL" < "$1" > "$dest-2" ; then
  echo "cannot insert Signed-off-by sentinel line in $1"
  exit 1
fi

# Make sure the trailer appears before any Signed-off-by trailers by inserting
# it as if it was a Signed-off-by trailer and then use sed to remove the
# Signed-off-by prefix and the Signed-off-by sentinel line.
# Avoid the --in-place option which only appeared in Git 2.8
# Avoid the --where option which only appeared in Git 2.15
if ! git -c trailer.where=before interpret-trailers \
         --trailer "Signed-off-by: $token: $value" < "$dest-2" |
     sed -e "s/^Signed-off-by: \($token: \)/\1/" \
         -e "/^Signed-off-by: SENTINEL/d" > "$dest" ; then
  echo "cannot insert $token line in $1"
  exit 1
fi

if ! mv "${dest}" "$1" ; then
  echo "cannot mv ${dest} to $1"
  exit 1
fi