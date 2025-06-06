# This script commits and pushes the corresponding files and
# directories to the respective GitHub repositories
#
# The first argument must be the commit message. It will default
# to "Update blog"

# Verify dependencies
# Hugo:
if command -v hugo >/dev/null 2>&1; then
  echo > /dev/null
else 
  echo "Error: command 'hugo' not found."
  exit 1
fi 

# Git:
if command -v git >/dev/null 2>&1; then
  echo > /dev/null
else 
  echo "Error: command 'git' not found."
  exit 1
fi 



repo=`realpath $0`
repo=`dirname $repo`
public=$repo/public

if [[ $# -gt 1 ]]; then
  echo "Error: expected >=1 arguments. Got $# instead."
  exit 1
fi

msg=$1
if [[ $# -lt 1 ]]; then
  msg="Update blog"
fi

if [[ ! -d $public ]]; then
  git clone https://github.com/aguirre-matteo/aguirre-matteo.github.io --depth 1 $public
fi 

if [[ ! -d $public/.git ]]; then
  echo "Warning: /public is not a git repository."
  echo "Overriding with remote public (aguirre-matteo.github.io)..."
  rm -rf $public
  git clone https://github.com/aguirre-matteo/aguirre-matteo.github.io --depth 1 $public
fi 

hugo -t blowfish

echo "Working in public repo (aguirre-matteo.github.io)"
git -C $public add .
git -C $public commit -m "\"$msg\""

echo "Working in source repo (website)"
git -C $repo add .
git -C $repo commit -m "\"$msg\""

echo "Pushing public repo..."
git -C $public push origin main 

echo "Pushing source repo..."
git -C $repo push origin main
