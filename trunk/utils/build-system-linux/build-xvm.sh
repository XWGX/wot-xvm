#!/bin/bash

#XVM builder for Linux
#Part of XVM build system
#Do not change anything in this file if you are not sure

#1. Detect WoT version
pushd config/ > /dev/null
flex_version=$(cat flex_version)
wot_version=$(cat wot_version)
popd > /dev/null

#2. Detect revision
pushd ../../ > /dev/null
revision=$(svnversion | head -c 4)
popd > /dev/null

#3. Define Flex SDK path
export FLEXSDK="/opt/apache-flex-$flex_version"
archive_postfix="_flex$flex_version"

#4. Build
pushd sh > /dev/null
./xvm-build.sh
popd > /dev/null

#5. Copy swfs,config,l10n,docs etc.
mkdir -p ../../temp/res_mods/"$wot_version"/gui/flash
mkdir -p ../../temp/res_mods/"$wot_version"/gui/scaleform

cp -f ../../bin/as3/*.swf ../../temp/res_mods/"$wot_version"/gui/flash/
rm -rf ../../bin/as3/

cp -rf ../../bin/* ../../temp/res_mods/"$wot_version"/gui/scaleform/

cp -rf ../../release/ ../../temp/res_mods/xvm/

rm -rf ../../release/*.swf
rm -rf ../../release/mods/*.swf
rm -rf ../../bin/*

#6. Build xvm-py
pushd ../../src/xpm/ > /dev/null
./build-all.sh
popd > /dev/null

cp -rf ../../bin/xpm/* ../../temp/res_mods/"$wot_version"/
rm -rf ../../bin/*

#7. Build archive
echo "$revision" >> ../../temp/"$revision"
pushd ../../temp/ > /dev/null && zip -9 -r -q "$revision"_xvm"$archive_postfix".zip ./ && popd > /dev/null

mv -f ../../temp/"$revision"_xvm"$archive_postfix".zip ../../bin/
rm -rf ../../temp/
