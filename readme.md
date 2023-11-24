# tCrossBar
tCrossBar is an interface for binding and visualizing macros more easily.  It uses visual elements to display as much information as possible, and is highly customizable in appearance.  Many features are familiar from tHotBar, but the interface is based around controller usage.

## How To Install
Download the release zip. Extract directly to your Ashita directory(the folder with ashita-cli.exe in it!). Everything should fall into place. tRenderer is no longer a part of tCrossBar. You can just load the addon now.

## Initial Setup
Upon initial login, you can type **/tc** to open a configuration window and configure the addon.  You can use the scale slider to make the displays larger or smaller, but you must click apply each time you change it to preview the change.  If trying to view single display, use the 'Allow Drag' button under the 'Single Layout' header to force it visible.  After you are happy with your layouts, go to the second tab and select a device mapping.  If you are on Ashita Interface 4.15 or lower, and using an xbox controller, be sure to choose the 'xbox_legacy' layout.  If on interface 4.16 or higher, the plain xbox layout is fine.  At present, the dualsense mapping should be usable for most directinput controllers, the xbox mapping should be usable for most xinput controllers, and the switchpro mapping should only be used for a switch pro controller.  I am happy to work one on one with anyone who has a controller that needs specialized mapping to expand the amount of available mappings.  Once you've selected a mapping, you can use the third tab to tweak controls if you are not happy with the defaults.  Finally, close the configuration window and you're ready to get started.

## Making Macros
To open the binding interface, simply hold both combo keys and both palette swap keys until a small imgui window pops up.  The default configuration for any controller will have these as L1+L2+R1+R2.  Afterward, you can press any macro combination to create a macro for it.  The macro interface itself requires mouse and keyboard for full customization, but has basic controller support.  To use it with a controller, you can navigate between Scope, Action Type, and Action with dpad up/down.  You can change any of these with dpad left/right, and holding the button down will cycle more rapidly.  Pressing your gamepad's confirm button will bind the macro, and your cancel button will return you to the binding interface to select a different macro.  The top button in your 4 button grouping swaps tabs, but controller cannot modify any settings in the appearance tab directly.

## Macro Combinations
tCrossBar supports up to 6 combos, each of which has 8 buttons to activate macros.  The combo keys can be bound to other buttons, but for simplicities sake I will refer to them as L2 and R2, which are the default configuration.  The combos are as follows:<br>

1. L2 held down
2. R2 held down
3. L2 and R2 held down, with L2 pressed first.
4. L2 and R2 held down, with R2 pressed first.  (This will only activate if 'Combo Priority' is checked on the configuration menu)
5. L2 tapped twice, and held down on the second tap.  (This will only activate if 'Double Tap' is checked on the configuration menu)
6. R2 tapped twice, and held down on the second tap.  (This will only activate if 'Double Tap' is checked on the configuration menu)
<br><br>

For each combo, you have up to 8 macro keys, which are your face buttons and dpad directions by default, but can be configured.  To activate a macro(or select it while in binding interface), simply execute the combo then press the button you'd like to activate.

## Binding Scope
Most of the options in the binding menu are self-explanatory, but scope may need a little further explanation.  When building your active macro set, tCrossBar will first look at your current palette and fill all squares it contains.  Then, if you have any empty squares, tCrossBar will look at your job bindings and fill them as able.  Finally, it will look at your global bindings and fill as able.  So, if you bind something to global, that slot will show up on all jobs and palettes until you override it with a job-specific or palette-specific macro.  If you bind something to job, it will show up on all palettes for that job until you override it with a palette-specific macro.

## Palettes
If you want multiple palettes of macros for a specific job, you can use typed commands to create and change them.  By default, every job contains an undeletable palette named Base.  Every time you change to a job, you will load onto the Base palette for that job.  These commands can be used from within tCrossBar macros, so you can do things like the oldschool SMN layout where your avatar summon would also swap to a palette for that avatar.  You can manually cycle palettes by holding a combo key and pressing the matching palette key.  By default, this would be R2>R1 for next palette, and L2>L1 for previous palette.

**/tc palette add [required: name]**
This will add a palette on your current job.

**/tc palette remove [required: name]**
This will delete a palette from your current job.  There is no way to recover bindings after doing this.

**/tc palette rename [required: old name] [required: new name]**
This will rename a palette, while preserving it's place in the order and bindings.

**/tc palette list**
This will print a list of palettes for your current job.

**/tc palette change [required: name]**
This instantly swaps to a specific palette.

**/tc palette next**
Change to next palette.

**/tc palette previous**
Change to previous palette.

## Custom Icons
The binding menu allows you to enter an image path to use your own images for any ability you want.  If you want to replace existing icons, or add new icons, you should do so by adding them to the directory:<br>
**Ashita/config/addons/tCrosstBar/resources**<br>
You can create this directory if it does not yet exist.  All image bindings will check config prior to checking the built in folder, so this allows you to use any file structure you want without worrying about colliding with the addon's resources.  The preferred method is to use action ID as the filename, but that is not required.  For example, to add a mighty strikes icon, you would use:<br>
**Ashita/config/addons/tCrossBar/resources/abilities/16.png**<br>
and you would enter the binding as:<br>
**abilities/16.png**<br>
You can also use the game's item resources directly, as tCrossBar will do when binding items.  To do this, simply enter the binding as **ITEM:28540** using the item id.  This can be found on FFXIAH.com or many other places.  This example would show a warp ring.  Status resources are supported similarly, using the notation STATUS:## with the status ID.

## Custom Layouts
If you want to adjust the layouts, the same thing applies!  Copy the included layout from:<br>
**Ashita/addons/tCrossBar/resources/layouts**<br>
to<br>
**Ashita/config/addons/tCrossBar/resources/layouts**<br>
prior to making changes.  Even if the original remains, layouts in config will always take priority.  Make sure to click 'refresh' in the config UI to detect new or altered layouts after editing files on disk.

## FAQ
### My settings reset when installing 2.0+.
This is expected. Settings, as configured through the '/tc' window, have been overhauled enough to be incompatible. You will need to configure them again. Note that bindings, your actual macros, will always remain compatible.

### tCrossBar crashes with a random error after upgrading to 2.0+.
Make sure you don't have any customized layouts from pre-2.0 in Ashita/addons/tCrossBar/resources/layouts. Layouts from prior to 2.0 are not compatible with 2.0+.

### My xbox controller isn't working right after upgrading to 2.0+.
Use the xbox_legacy controller profile until you've also upgraded to Ashita 4.16+.

#### More to come as common questions arise.