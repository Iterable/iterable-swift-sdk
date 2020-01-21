# Advanced Inbox

The protocol `IterableInboxViewControllerViewDelegate` defines properties of `IterableInboxViewController` that can be modified. For example, if you want to only show certain messages in  inbox, you can set the `filter` property to define inbox messages that will be shown. Or, if you want to sort messages by a different order, you can set the `comparator` property. To achieve this you will have to set `viewDelegate` property of `IterableInboxViewController` to an implementation of `IterableInboxViewControllerViewDelegate`.

In this example we show you how to set `viewDelegate` property of `IterableInboxViewController` to a custom implementation of  `IterableInboxViewControllerViewDelegate`. Step by step instructions are below:

1. Create a class `AdvancedInboxViewDelegate` that implements the `IterableInboxViewControllerViewDelegate` protocol. Our example of `IterableInboxViewControllerViewDelegate` does three things. 
	1. It sets nib names for individual inbox cells via `customNibNameMapper` property.
	2. it maps messages to section number via `messageToSectionMapper` property.
	3. It renders additional `discount` field and a button.


2. In your storyboard, add a `UITableViewController` and set the custom class name to `IterableInboxViewController`. You can also set properties of `UITableView` such as `.grouped` so that you can view separate sections.

3. Set `view delegate class name` property in attributes inspector to `inbox_customization.AdvancedInboxViewDelegate`. __IMPORTANT__: please note that the module name must be present. Here it is `inbox_customization`, in your case it will be different.

4. Create a custom xib file called `AdvancedInboxCell.xib` (or whatever name you choose) by copying the example file here. Change the layout and add extra fields if necessary. Connect the outlets for your extra fields. Other outlets will be already connected. In order to load this custom cell you will need to set `customNibNameMapper` to load this nib. See `AdvancedInboxViewDelegate` class regarding how to do this.
