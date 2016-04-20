# GenericDataSource

[![Version](https://img.shields.io/cocoapods/v/GenericDataSource.svg?style=flat)](http://cocoapods.org/pods/GenericDataSource)
[![License](https://img.shields.io/cocoapods/l/GenericDataSource.svg?style=flat)](http://cocoapods.org/pods/GenericDataSource)
[![Platform](https://img.shields.io/cocoapods/p/GenericDataSource.svg?style=flat)](http://cocoapods.org/pods/GenericDataSource)

A generic small composable components for data source implementation for `UITableView` and `UICollectionView` written in Swift.

## Features

- [x] Basic data source to manage set of cells binded by array of items.
- [x] Composite data source (multi section) manages children data sources each child represent a section.
- [x] Composite data source (single section) manages children data sources all children are in the same section. Children depends on sibiling with 0 code. So, if the first child produces 2 cells the second one render its cells starting 3rd cell. If the first child produces 5 cells, second child will render its cells starting 6th cell.
- [x] Basic data source responsible for its cell size/height.
- [x] Basic data source responsible for highlighting/selection/deselection using `selectionHandler`.
- [x] Comprehensive Unit Test Coverage
- [x] [Complete Documentation](http://cocoadocs.org/docsets/Alamofire)

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate GenericDataSource into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

pod 'GenericDataSources'
```

### Manually

Add GenericDataSource.xcodeproj to your project file by drag and drop. 

You can then consult to [Adding an Existing Framework to a Project](https://developer.apple.com/library/ios/recipes/xcode_help-structure_navigator/articles/Adding_a_Framework.html)

---
## Usage

### Basic Data Source Example
Create a basic data source and bind it to to a table view.

```swift
let dataSource = BasicBlockDataSource<Example, UITableViewCell>(reuseIdentifier: "cell") { (item: Example, cell: UITableViewCell, _) -> Void in
    cell.textLabel?.text = item.title
    cell.contentView.backgroundColor = nil
}

// Need to keep a strong reference to our data source.
self.dataSource = dataSource

tableView.ds_useDataSource(dataSource)
dataSource.items = <<retrieve items>> // Can be called later no need to set them immediately.

// Optionally adding a selection handler
let selectionHandler = BlockSelectionHandler<Example, UITableViewCell>()
selectionHandler.didSelectBlock = { [weak self] dataSource, _, indexPath in
    let item = dataSource.itemAtIndexPath(indexPath)
    self?.performSegueWithIdentifier(item.segue, sender: self)
}
dataSource.setSelectionHandler(selectionHandler)
```

### Single Section Example

We need to show 2 different types of cells in the same section (color cells and contacts information cells)

```swift
// We can use BasicDataSource by subclassing it or use BasicBlockDataSource as in the previous example.
class ColorsDataSource: BasicDataSource<Color, UITableViewCell> {

    // This is needed as of swift 2.2, because if you subclassed a generic class, initializers are not inherited.
    override init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView, configureCell cell: CellType, withItem item: Color, atIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = item.color
    }
}

class ContactsDataSource<CellType: ContactCell>: BasicDataSource<Contact, ContactCell> {

    // This is needed as of swift 2.2, because if you subclassed a generic class, initializers are not inherited.
    override init(reuseIdentifier: String) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView, configureCell cell: ContactCell, withItem item: Contact, atIndexPath indexPath: NSIndexPath) {
        cell.configureForContact(item)
    }
}

extension ContactCell {
    private func configureForContact(contact: Contact) {
        textLabel?.text = contact.name
        detailTextLabel?.text = contact.email
    }
}

// ....
// Then in the view controller.
override func viewDidLoad() {
    super.viewDidLoad()
    
    let dataSource = CompositeDataSource(type: .SingleSection)
    // strong refernce
    self.dataSource = dataSource
    let colorsDataSource = ColorsDataSource(reuseIdentifier: "color")
    let contactsDataSource = ContactsDataSource(reuseIdentifier: "contact")
    
    // add the data sources
    dataSource.addDataSource(contactsDataSource)
    dataSource.addDataSource(colorsDataSource)
    
    tableView.ds_useDataSource(dataSource)
    
    // optionally selection handler
    colorsDataSource.setSelectionHandler(AlertNameSelectionHandler(typeName: "color"))
    contactsDataSource.setSelectionHandler(AlertNameSelectionHandler(typeName: "contact"))

    // specify different heights
    colorsDataSource.itemHeight = 30
    contactsDataSource.itemHeight = 50

    colorsDataSource.items = << Retrieve Colors >>
    contactsDataSource.items = << Retrieve Contacts >>
}

```
Benefits:

1. Code will allow you to reuse the data sources since they are now independent of the view controller.
2. There are no `if` `else` now to check which item is it and dequeue the cell accordingly, it's all done for us by the amazing `CompositeDataSource`.
3. It's also possible to change the ordering by just add the colors data source first.
4. To have the cells into multiple sections all you need to do is just change `CompositeDataSource(type: .SingleSection)` to `CompositeDataSource(type: .MultiSection)`.

### Multiple Section Example

Just use the same example above and change `CompositeDataSource(type: .SingleSection)` to `CompositeDataSource(type: .MultiSection)`!

### More Complex Examples

Will involove creating one `MultiSection` composite data source with children `SingleSection` composite data sources that manages a section each will have multiple data sources. It's possible to have basic and single section data sources children of the multi section composite data source.

Check the Examples application for complete implementation.

--
## Attribution

The main idea comes from [WWDC 2014 Advanced User Interfaces with Collection Views] (https://developer.apple.com/videos/play/wwdc2014/232/)
written in swift with generics.

## Author

Mohamed Afifi, mohamede1945@gmail.com

## License

GenericDataSource is available under the MIT license. See the LICENSE file for more info.
