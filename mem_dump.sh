#!/bin/bash

mkdir /tmp/uac/

cd /tmp/uac/

wget https://github.com/tclahr/uac/archive/refs/heads/main.zip -O /tmp/uac/main.zip

unzip -o /tmp/uac/main.zip -d /tmp/uac/

cd /tmp/uac/uac-main/

./uac -a artifacts/memory_dump/avml.yaml /tmp