#!/bin/sh
# usage: mkicns icon.png

ICON=$1; shift

mkdir -p MyIcon.iconset
sips -z 16 16     ${ICON} --out MyIcon.iconset/icon_16x16.png
sips -z 32 32     ${ICON} --out MyIcon.iconset/icon_16x16@2x.png
sips -z 32 32     ${ICON} --out MyIcon.iconset/icon_32x32.png
sips -z 64 64     ${ICON} --out MyIcon.iconset/icon_32x32@2x.png
sips -z 128 128   ${ICON} --out MyIcon.iconset/icon_128x128.png
sips -z 256 256   ${ICON} --out MyIcon.iconset/icon_128x128@2x.png
sips -z 256 256   ${ICON} --out MyIcon.iconset/icon_256x256.png
sips -z 512 512   ${ICON} --out MyIcon.iconset/icon_256x256@2x.png
sips -z 512 512   ${ICON} --out MyIcon.iconset/icon_512x512.png
sips -z 1024 1024 ${ICON} --out MyIcon.iconset/icon_512x512@2x.png

iconutil -c icns MyIcon.iconset
