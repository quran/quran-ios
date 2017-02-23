# GenericDataSource

[![Version](https://img.shields.io/cocoapods/v/GenericDataSources.svg?style=flat)](http://cocoapods.org/pods/GenericDataSources)
[![License](https://img.shields.io/cocoapods/l/GenericDataSources.svg?style=flat)](http://cocoapods.org/pods/GenericDataSources)
[![Platform](https://img.shields.io/cocoapods/p/GenericDataSources.svg?style=flat)](http://cocoapods.org/pods/GenericDataSources)

A generic small composable components for data source implementation for `UITableView` and `UICollectionView` written in Swift.

**Supports Swift 3.0**

## Features

- [x] Basic data source to manage set of cells binded by array of items.
- [x] Composite data source (multi section) manages children data sources each child represent a section.
- [x] Composite data source (single section) manages children data sources all children are in the same section. Children depends on sibiling with 0 code. So, if the first child produces 2 cells the second one render its cells starting 3rd cell. If the first child produces 5 cells, second child will render its cells starting 6th cell.
- [x] Basic data source responsible for its cell size/height.
- [x] Basic data source responsible for highlighting/selection/deselection using `selectionHandler`.
- [x] Comprehensive Unit Test Coverage
- [x] [Complete Documentation](http://cocoadocs.org/docsets/GenericDataSources)

## Requirements

- iOS 7.0+
- Xcode 8
- Swift 3.0

## Installation

### CocoaPods

To integrate GenericDataSource into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

pod 'GenericDataSources'
```
**IMPORTANT:** The pod name is GenericDataSource**s** with "s" at the end.

### Carthage

To integrate GenericDataSource into your Xcode project using Carthage, specify it in your Cartfile:

```bash
github "GenericDataSource/GenericDataSource"
```

### Manually

Add GenericDataSource.xcodeproj to your project file by drag and drop. 

You can then consult to [Adding an Existing Framework to a Project](https://developer.apple.com/library/ios/recipes/xcode_help-structure_navigator/articles/Adding_a_Framework.html)

---
## Usage

Let's start with a complex example from high level and then explain in more details

### Real World Example

Suppose we want to implement the following screen as `UICollectionView`.

![Read World Example Screenshot](https://cloud.githubusercontent.com/assets/5665498/17307249/5c1bbc84-5834-11e6-97fc-4e8caa238fd6.PNG)

1. We will create cells as we do normally.
    * A Cell for the  top part title and See All including a nested `UICollectionView`.
    * A cell for the Quick Links.
    * A cell for the actions (Add Payment Method, New to the App Store?, etc.). We will assume one cell and we will reuse it.
    * A cell for Redeem, Send gifts, etc.
2. Now we need to think about DataSources.
3. It's simple, one data source for each cell type (`BasicDataSource`).
4. We can then create composite data sources that holds those basics. like that
    * `CompositeDataSource(sectionType: .SingleSection)` for the Top, quick links, add payment, etc. data sources.
    * `CompositeDataSource(sectionType: .MultiSection)` for the first composite and the last part (Redeem, Gifts).
5. Bind the multi section compsite data source to the collection view and that's it.
6. See how we think structurely about our UI and data sources instaed of one big cell.

See how we can do it in the following code
```Swift
// 1. Cells
class FeaturedTopCell: UICollectionViewCell {}
class QuickLinksCell: UICollectionViewCell {}
class ActionBlueCell: UICollectionViewCell {}
class ActionRoundedRectCell: UICollectionViewCell {}

// 2. Basic Data Sources
class FeaturedTopDataSource: BasicDataSource<FeaturedModel, FeaturedTopCell>  { }
class QuickLinksDataSource: BasicDataSource<String, QuickLinksCell>  { }
class ActionBlueDataSource: BasicDataSource<String, ActionBlueCell>  { }
class ActionRoundedRectDataSource: BasicDataSource<String, ActionRoundedRectCell>  { }

// 3. Create data source instances once.
let featuredDS = FeaturedTopDataSource()
let quickLinksDS = QuickLinksDataSource()
let actionBlueDS = ActionBlueDataSource()
let actionRoundedRectDS = ActionRoundedRectDataSource()

// 4. Create first section hierarchy.
let firstSection = CompsiteDataSource(type: .SingleSection)
firstSection.add(featuredDS)
firstSection.add(quickLinksDS)
firstSection.add(actionBlueDS)

// 5. Complete the hierarchy.
let outerDS = CompsiteDataSource(type: .MultiSection)
outerDS.add(firstSection)
outerDS.add(actionRoundedRectDS)

// 6. set data sources to the collection view.
collectionView.ds_useDataSource(outerDS)

// 7. You can set the data later or earlier.
featuredDS.items = [FeaturedModel()]
quickLinksDS.items = ["Quick Links"]
actionBlueDS.items = ["Add Payment Method", "New to the App Store", "About in-App Purchases", "Parents' Guide to iTunes", "App Collections"]
actionRoundedRectDS.items = ["Redeem", "Send Gifts"]

// 8. We can reload the collection view if the data is loaded async.
collectionView.reloadData()
```

There are many benifits of doing that:

1. You don't need to think about indexes anymore, all is handled for us. Only think about how you can structure your cells into smaller data sources.
2. We can switch between `UITableView` and `UICollectionView` without touching data sources or models. Only change the cells to inhert from `UITableViewCell` and everything else works.
3. We can add/delete/update cells easily. For example we decided to add more blue links. We can do it by just adding new item to the array passed to the data source.
4. We can re-arrange cells as we want. Just move around the `addDataSource` calls.

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

    override func ds_collectionView(collectionView: GeneralCollectionView, configure cell: CellType, with item: Color, at indexPath: IndexPath) {
        cell.backgroundColor = item.color
    }
}

class ContactsDataSource<CellType: ContactCell>: BasicDataSource<Contact, ContactCell> {

    override func ds_collectionView(collectionView: GeneralCollectionView, configure cell: ContactCell, with item: Contact, at indexPath: IndexPath) {
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
    
    let dataSource = CompositeDataSource(sectionType: .SingleSection)
    // strong refernce
    self.dataSource = dataSource
    let colorsDataSource = ColorsDataSource(reuseIdentifier: "color")
    let contactsDataSource = ContactsDataSource(reuseIdentifier: "contact")
    
    // add the data sources
    dataSource.add(contactsDataSource)
    dataSource.add(colorsDataSource)
    
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
4. To have the cells into multiple sections all you need to do is just change `CompositeDataSource(sectionType: .SingleSection)` to `CompositeDataSource(sectionType: .MultiSection)`.

### Multiple Section Example

Just use the same example above and change `CompositeDataSource(sectionType: .SingleSection)` to `CompositeDataSource(sectionType: .MultiSection)`!

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
