### _Draft_ ###
# XVM release deploying #


## Building ##
  * Increase XVM version
    * Update version number at `/src/xvm/src/com/xvm/Defines.as` (`public static const XVM_VERSION:String`)
    * Update version number at `/release/doc/ChangeLog-*.txt` files
    * Update content content in changelog files according new feautures and bugfixes
    * Update version number at [ReleaseInfo](https://code.google.com/p/wot-xvm/wiki/ReleaseInfo) wiki page

  * Update Vehicle Data (for WoT major updates)
    1. Open `/src/vehicle-bank-parser/VehicleBankParser.sln` project in Microsoft Visual C# 2010 Express. Not 2012.
    1. Right click on `VehicleBankParser`. Properties. Settings. Edit settings according to your paths.
    1. Run project.
    1. This will generate vehicles file. It will contain info for all vehicles hp, names, levels etc including new vehicles released with new WoT version

  * Update map sizes (for major WoT updates)
    1. Define size and system name at `wot.Minimap.model.mapSize.MapInfoData`

  * Update and patch WG.net AS2 .swf files
    1. Unzip original WoT file `[WoT]/res/packages/gui.pkg` (you can use 7-zip for it)
    1. Overwrite /src/xvm-as2/swf/orig files with new ones from `scaleform` folder
    1. Run 1.make-patched-swfs.bat at `/src/xvm-as2/swf/` at cygwin. Diffutils and patch must be installed.'

  * Update and patch WG.net AS3 .swf files
    1. TODO

  * Build AS2 Flash files
    1. Build all `.as2proj` files from `/src/xvm-as2/` folder

  * Build AS3 Flash files
    1. Build `/src/xvm/wg.as3proj`
    1. Build `/src/xvm/xvm.as3proj`
    1. Build other files in this folder

  * Build Python files
    1. Run `/src/spm/build-all.sh` script from Cygwin.

  * Update clanicons
    1. Run all update scripts at `/addons/clanicons` folder

## File hierarchy in archive ##
  * res\_mods
    * x.x.xx
      * gui
        * flash
          * _patched Application.swf_
        * scaleform
          * _AS2 files_
      * scripts
        * _python files_
    * xvm
      * configs
        * _configs_
      * doc
        * _readme and changelog_
      * l10n
        * _localization files_
      * mods
        * _AS3 files_
      * res
        * clanicons
          * _clanicons_
        * _6-sense image_