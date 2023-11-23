#! /bin/sh

gem_file=$(ls -1 | grep '\.gem$' | head -n 1)

if [ -z "$gem_file" ]; then
    echo "Error : no .gem file was found"
    exit 1
fi

gem nexus --url $NEXUS_DEPLOY_URL --credential $NEXUS_CREDENTIALS $gem_file
