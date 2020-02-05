# Custom Inbox

This example shows you how to change the layout, font etc of inbox cells. The idea is simple. You create a custom `UITableViewCell` in storyboard and you set the `cell nib name` property to your custom cell. See below for step by step instructions

1. You will need to create a custom UITableViewCell. Easiest way is to copy the file `CustomInboxCell.xib` that is present in this directory (of this README file that you are reading) to your project. 

2. Once you have copied and added `CustomInboxCel` to your project, you can change any aspect of the layout, font etc in the xib file.

3. In your storyboard, add a view controller and set custom class to `IterableInboxNavigationViewController`. 

4. Now click on attributes inspector and set `cell nib name` to `CustomInboxCell` (note no xib).  

__Note:__ It is not recommended but you may also create your UITableViewCell from scratch. You must make sure that the custom class is set to `IterableInboxCell` and that all the outlets are conneted. That is why we recommend that you copy/paste the provided xib file.
