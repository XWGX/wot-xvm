# Building on `*`nix systems #

  * Prerequisites
    * Apache Flex http://flex.apache.org/
    * Bash https://www.gnu.org/software/bash/bash.html
    * Diffutils http://www.gnu.org/software/diffutils/
    * Mono http://www.mono-project.com/
    * Mtasc http://www.mtasc.org/
    * Patch http://savannah.gnu.org/projects/patch/
    * Python 2.7 https://www.python.org/
    * RABCDAsm (already bundled for amd64) https://github.com/CyberShadow/RABCDAsm
    * OpenJRE 6/7 http://www.oracle.com/technetwork/java/javase/downloads/index.html
    * Subversion http://subversion.apache.org/
    * SWFmill http://swfmill.org/
    * Zip http://www.info-zip.org/Zip.html

> Install this programs (except Apache Flex and RABCDasm) using your package manager.

  1. Install Apache Flex
    1. Unpack Flex binary archive (http://flex.apache.org/download-binaries.html) to `/opt/apache-flex-x.xx/` (where x.xx is a Flex version)
    1. `cd /opt/apache-flex-x.xx/`
    1. install playerglobal.swc using "`git clone git://github.com/nexussays/playerglobal.git frameworks/libs/player`" command
  1. Build XVM
    1. clone XVM using "`svn checkout http://wot-xvm.googlecode.com/svn/trunk/ wot-xvm`" command
    1. `cd wot-xvm/utils/build-system-linux/`
    1. `./build-xvm.sh`
    1. Done! Grab your zip archive with XVM in "[wot-xvm]/bin/" folder.

Notes:
  * RABCDAsm bundled only for amd64 Linux. If you want to use it on i386 Linux or other OS you should recompile RABCDAsm and replace files in "`[wot-xvm]/utils/build-system-linux/bin/`" folder.