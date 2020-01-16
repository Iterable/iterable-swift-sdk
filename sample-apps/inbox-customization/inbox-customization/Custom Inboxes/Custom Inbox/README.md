# Custom Inbox

You will need to create a custom UITableViewCell. Easiest way is to copy the file `CustomInboxCell1.xib` that is present in this directory (of this README file) to your project. 

Now you can change any aspect of the layout, font etc in the xib file.

In your storyboard, set custom class to `IterableInboxNavigationViewController`. Now click on attributes inspector and set `cell nib name` to `CustomInboxCell1` (note no xib).  

Note: It is not recommended but you may also create your UITableViewCell from scratch. You must make sure that the custom class is set to `IterableInboxCell` and all the outlets are conneted. If you copy/paste the provided xib then there is no need to worry about it.

