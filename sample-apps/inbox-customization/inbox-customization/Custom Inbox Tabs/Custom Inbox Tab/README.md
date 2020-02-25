# Custom Inbox

This example shows you how to change the layout, font etc of inbox cells. The idea is simple. You create a custom `UITableViewCell` in storyboard and you set the `cell nib name` property to your custom cell. See below for step by step instructions.

1. You will need to create a custom UITableViewCell. Easiest way is to copy the `SampleInboxCell.xib` file that is present in `[swift_sdk_location]/swift-sdk/Resources/SampleInboxCell.xib`. See the __How to copy inbox cell xib file from IterableSDK__ section for details.

2. Once you have copied and added the `SampleInboxCell` to your project, you can change its name to `CustomInboxCell` and also change any aspect of the layout, font etc in the xib file.

3. In your storyboard, add a view controller and set custom class to `IterableInboxNavigationViewController`. 

4. Now click on attributes inspector and set `cell nib name` to `CustomInboxCell` (note no '.xib').  


## How to copy SampleInboxCell xib file from IterableSDK
1. `File -> Open Quickly` menu. Then type `SampleInboxCell`.
2. When the file opens click on `File -> Show in Finder` menu.
3. Drag this file from Finder to your project.
4. __IMP:__ Make sure that you create a __copy__ and not a reference to the original file. To do this, make sure that you have selected the `Copy items if needed` option. 

__Note:__ It is not recommended but you may also create your UITableViewCell from scratch instead of copying. You must make sure that the custom class is set to `IterableInboxCell`, the module is set to `IterableSDK` and that all the outlets are conneted. That is why we recommend that you copy/paste the provided xib file.
