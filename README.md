# XFunnyEditor

Xcode plugin to display an image on the background of the editor

![Screenshot](https://raw.github.com/STAR-ZERO/XFunnyEditor/master/screenshot.png)

## Install

### Manual

Build the XFunnyEditor target in the Xcode project and the plugin will automatically be installed in `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`. Restart Xcode.

### Alcatraz

Install from [Alcatraz](https://github.com/supermarin/Alcatraz) package manager. Restart Xcode.

## Uninstall

Delete the following directory: `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/XFunnyEditor.xcplugin`.

## Usage

To Start XFunnyEditor setting screen, select `XFunnyEditor` from `Edit` menu.

Please specify image file and transparency and position from setting screen.

If you want to disable, please select the menu again.

## Support version

This plugin is developed in MaxOS 10.8 and Xcode 5.0

## Known Issues :(

* Crash By using the XFunnyEditor setting screen in the except source code editor.
* Occasional crash when you select the menu.

## License

[MIT License](https://github.com/STAR-ZERO/XFunnyEditor/blob/master/LICENSE)
