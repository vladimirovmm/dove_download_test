#!/bin/bash

if [ ! -e releases.json ]; then
  # download releases.json
  curl -u vladimirovmm:$token \
    -o "releases.json" \
    -s https://api.github.com/repos/pontem-network/move-tools/releases
fi

dove_version=""
if [[ $1 == "latest" || $1 == "new" || $1 == "last" || -z $1 ]]; then
  dove_version=$(cat "releases.json" | jq -r '.[0] .tag_name')
else
  if [ ! $(cat "releases.json" |
    jq ".[] | select(.tag_name==\"${1}\") .tag_name") ]; then
    echo "{$1} The specified version of dove was not found"
    exit 1
  fi
  dove_version=$1
fi

download_type=""
filename="dove"
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "freebsd"* || "$OSTYPE" == "cygwin" ]]; then
  download_type="linux-x86_64"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  download_type="darwin-x86_64"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  download_type="win-x86_64.exe"
  filename="dove.exe"
else
  echo "Unknown OS"
  exit 2
fi

download_url=$(cat "releases.json" |
  jq -r ".[] | select(.tag_name==\"${dove_version}\") .assets | .[] | select(.name|test(\"^dove-${dove_version}-${download_type}\")) | .browser_download_url")

if [ ! -e $filename ]; then
  curl -sL --fail \
    -H "Accept: application/octet-stream" \
    -u vladimirovmm:$token \
    -o $filename \
    -s $download_url
fi

filename="./$filename"
ls
echo "run: $filename -V"
chmod 1755 $filename
$filename -V
