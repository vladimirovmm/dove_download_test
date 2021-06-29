#!/bin/bash

if [ ! -e "releases.json" ] || [ $(expr $(stat -c %Y "releases.json") + 600) -le $(date +%s) ]; then
  echo "Download: releases.json"
  curl -o "releases.json" \
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

if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "freebsd"* || "$OSTYPE" == "cygwin" ]]; then
  download_type="linux-$HOSTTYPE"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  download_type="darwin-$HOSTTYPE"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  download_type="win-$HOSTTYPE.exe"
else
  echo "Unknown OS"
  exit 2
fi

filename="dove_${dove_version}-${download_type}"

if [ ! -e $filename ]; then
  download_url=$(cat "releases.json" |
      jq -r ".[] | select(.tag_name==\"${dove_version}\") .assets | .[] | select(.name|test(\"^dove-${dove_version}-${download_type}\")) | .browser_download_url")
  echo "Download: $download_url"
  curl -sL --fail \
    -H "Accept: application/octet-stream" \
    -o $filename \
    -s $download_url
fi

filename="./$filename"
echo "run: $filename -V"
chmod 1755 $filename
$filename -V

if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "freebsd"* || "$OSTYPE" == "cygwin" ]]; then
    mkdir -p /home/$USER/.local/bin
    ln -sf "$(pwd)/$filename" /home/$USER/.local/bin/dove
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -e /usr/local/bin ]; then
        ln -sf "$(pwd)/$filename" /usr/local/bin/dove
    elif [ -e /usr/bin ]; then
        ln -sf "$(pwd)/$filename" /usr/bin/dove
    else
        echo "Failed to create a link"
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    cp $filename "dove.exe"
    export PATH=$PATH:`pwd`
else
    echo "Unknown OS"
    exit 2
fi
echo "{dove}={`pwd`/$filename}" >> $GITHUB_ENV

dove -V
