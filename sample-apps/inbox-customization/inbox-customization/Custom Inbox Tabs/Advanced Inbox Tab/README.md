# Advanced Inbox

The protocol `IterableInboxViewControllerViewDelegate` defines properties of `IterableInboxViewController` that can be modified. For example, if you want to only show certain messages in inbox, you can set the `filter` property to define inbox messages that will be shown. Or, if you want to sort messages by a different order, you can set the `comparator` property. To achieve this you will have to set `viewDelegate` property of `IterableInboxViewController` to an implementation of `IterableInboxViewControllerViewDelegate`.

In this example we show you how to set `viewDelegate` property of `IterableInboxViewController` to a custom implementation of  `IterableInboxViewControllerViewDelegate`. Step by step instructions are below:

1. Create a class `AdvancedInboxViewDelegate` that implements the `IterableInboxViewControllerViewDelegate` protocol. Our example of `IterableInboxViewControllerViewDelegate` does three things. 
    1. It sets nib names for individual inbox cells via `customNibNameMapper` property. This enables us to display different inbox cells for different messages.
    2. it maps messages to section number via `messageToSectionMapper` property. This enables us to display multiple sections.
    3. It renders values for the additional `discount` field.


2. In your storyboard, add a `UIViewController` and set the custom class name to `IterableInboxNavigationViewController`. In the `Attributes Inspector` for this class set the following:
    1. Set `Nav Title` property to `Advanced Inbox`.
    2. Set `View Delegate Class Name` property to `inbox_customization.AdvancedInboxViewDelegate`.
    3. Set `Group Sections` to `On`.
    4. Set `Large Titles` to `On`.

3. Create a custom xib file called `AdvancedInboxCell.xib` (or whatever name you choose) by copying the example file here. Follow instructions for copying xib file from `Custom Inbox Tab` README file. Change the layout and add extra fields if necessary. Connect the outlets for your extra fields. Other outlets will be already connected. In order to load this custom cell you will need to set `customNibNameMapper` to load this nib. See `AdvancedInboxViewDelegate` class regarding how to do this.
