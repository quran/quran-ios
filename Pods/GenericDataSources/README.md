# GenericDataSource

[![Version](https://img.shields.io/cocoapods/v/GenericDataSources.svg?style=flat)](http://cocoapods.org/pods/GenericDataSources)
[![Swift Version](https://img.shields.io/badge/Swift-3.0+-orange.svg)](https://swift.org)

[![Build Status](https://travis-ci.org/GenericDataSource/GenericDataSource.svg?branch=master)](https://travis-ci.org/GenericDataSource/GenericDataSource)
[![Coverage Status](https://codecov.io/gh/GenericDataSource/GenericDataSource/branch/master/graphs/badge.svg)](https://codecov.io/gh/GenericDataSource/GenericDataSource/branch/master)
[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/GenericDataSources.svg)](http://cocoadocs.org/docsets/GenericDataSources)

A generic small reusable components for data source implementation for `UITableView`/`UICollectionView` written in Swift.

## Features

- [x] `BasicDataSource` easily bind model to cells with automatic dequeuing.
- [x] `SegmentedDataSource` easily build segmented controls or for empty state of your `UICollectionView`/`UITableView` data source.
- [x] `CompositeDataSource` builds complex cells/models structure with easy to use components (`BasicDataSource` `SegmentedDataSource` or other `CompositeDataSource`).
- [x] `UICollectionView` supplementary, `UITableView` header, and footer views support.
- [x] Ability to override any data source method from `UIKit` classes.
- [x] Comprehensive Unit Test Coverage.
- [x] [Complete Documentation](http://cocoadocs.org/docsets/GenericDataSources)

## Requirements

- iOS 8.0+
- Xcode 8
- Swift 3.0+

## Installation

#### CocoaPods

To integrate `GenericDataSource` into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'GenericDataSources'
```

**IMPORTANT:** The pod name is GenericDataSource**s** with "s" at the end.

#### Carthage

To integrate GenericDataSource into your Xcode project using Carthage, specify it in your Cartfile:

```bash
github "GenericDataSource/GenericDataSource"
```

#### Manually

Add `GenericDataSource.xcodeproj` to your project file by drag and drop.

You can then consult to [Adding an Existing Framework to a Project](https://developer.apple.com/library/ios/recipes/xcode_help-structure_navigator/articles/Adding_a_Framework.html).

---
## Example

### Basic Data Source Example

#### UITableView
Create a basic data source and bind it to to a table view.

```swift
let dataSource = BasicBlockDataSource<Example, BasicTableViewCell>() { (item: Example, cell: BasicTableViewCell, indexPath) -> Void in
    cell.titleLabel?.text = item.title
}

// Need to keep a strong reference to our data source.
self.dataSource = dataSource

// register the cell
tableView.ds_register(cellClass: BasicTableViewCell.self)
// bind the data source to the table view
tableView.ds_useDataSource(dataSource)

dataSource.items =  <<retrieve items>> // Can be set and altered at anytime
```

That's it! Your first data source is implemented. No dequeuing! no casting! simple and smart.

#### UICollectionView
Let's now take it to the next level. Suppose after we implemented it, the requirements changed and we need to implement it using `UICollectionView`.

```swift
let dataSource = BasicBlockDataSource<Example, BasicCollectionViewCell>() { (item: Example, cell: BasicCollectionViewCell, indexPath) -> Void in
    cell.titleLabel?.text = item.title
}

// Need to keep a strong reference to our data source.
self.dataSource = dataSource

// register the cell
collectionView.ds_register(cellClass: BasicCollectionViewCell.self)
// bind the data source to the collection view
collectionView.ds_useDataSource(dataSource)

dataSource.items =  <<retrieve items>> // Can be set and altered at anytime
```

__All you need to do is change the cell class and of course the table view to collection view.__

Actually this opens the door for so much possibilities. You can inherit from `BasicDataSource` and implement your custom generic data source that is based on a protocol implemented by the cell and you don't need to repeat the configuration part. You would create data source like that.
```
let dataSource1 = CustomDataSource<BasicTableViewCell>() // for table view
let dataSource2 = CustomDataSource<BasicCollectionViewCell>() // for collection view
```

### App store Featured Example

Suppose we want to implement the following screen, the App Store featured tab.

![App Store Example Screenshot](https://cloud.githubusercontent.com/assets/5665498/24696881/6a4e7778-19eb-11e7-9e65-d96eac0dce76.gif)

__If you want to have a look at the complete source code, it is under Example project -> `AppStoreViewController.swift`.__

1. We will create cells as we do normally.
2. Now we need to think about DataSources.
3. It's simple, one data source for each cell type (`BasicDataSource`).
4. `CompositeDataSource(sectionType: .single)` for the table view rows. Since these rows are of different cell types.
5. `SegmentedDataSource` for switching between loading and data views.
6. Bind the `SegmentedDataSource` data source to the table view and that's it.
7. See how we think structurally about our UI and data sources instead of one big cell.

One thing we didn't talk about is the `UICollectionView` of the featured section cells. It's very simple, just `BasicDataSource`.

See how we can implement the screen in the following code:

1. Create the cells.
```Swift
class AppStoreFeaturedSectionTableViewCell: UITableViewCell { ... }
class AppStoreQuickLinkLabelTableViewCell: UITableViewCell { ... }
class AppStoreQuickLinkTableViewCell: UITableViewCell { ... }
class AppStoreFooterTableViewCell: UITableViewCell { ... }
class AppStoreLoadingTableViewCell: UITableViewCell { ... }
```
2. Create `BasicDataSource`s.
```Swift
class AppStoreLoadingDataSource: BasicDataSource<Void, AppStoreLoadingTableViewCell> {
    // loading should take full screen size.
    override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.size
    }
}
class AppStoreFooterDataSource: BasicDataSource<Void, AppStoreFooterTableViewCell> { ... }
class AppStoreQuickLinkDataSource: BasicDataSource<FeaturedQuickLink, AppStoreQuickLinkTableViewCell> { ...  }
class AppStoreFeaturedAppsDataSource: BasicDataSource<FeaturedApp, AppStoreFeaturedAppCollectionViewCell> { ... }
class AppStoreFeaturedAppsSectionDataSource: BasicDataSource<FeaturedSection, AppStoreFeaturedSectionTableViewCell> { ... }
class AppStoreQuickLinkLabelDataSource: BasicDataSource<String, AppStoreQuickLinkLabelTableViewCell> { ... }
```
3. Create `CompositeDataSource` that holds the featured page.
```Swift
class AppStoreFeaturedPageDataSource: CompositeDataSource {
    init() { super.init(sectionType: .single)] }

    var page: FeaturedPage? {
        didSet {
            // remove all existing data sources
            removeAllDataSources()

            guard let page = page else {
                return
            }

            // add featured apps
            let featuredApps = AppStoreFeaturedAppsSectionDataSource()
            featuredApps.setSelectionHandler(UnselectableSelectionHandler())
            featuredApps.items = page.sections
            add(featuredApps)

            // add quick link label
            let quickLinkLabel = AppStoreQuickLinkLabelDataSource()
            quickLinkLabel.setSelectionHandler(UnselectableSelectionHandler())
            quickLinkLabel.items = [page.quickLinkLabel]
            add(quickLinkLabel)

            // add quick links
            let quickLinks = AppStoreQuickLinkDataSource()
            quickLinks.items = page.quickLinks
            add(quickLinks)

            // add footer
            let footer = AppStoreFooterDataSource()
            footer.setSelectionHandler(UnselectableSelectionHandler())
            footer.items = [Void()] // we add 1 element to show the footer, 2 elements will show it twice. 0 will not show it.
            add(footer)
        }
    }
}
```

4. Create the outer most data source.
```Swift
class AppStoreDataSource: SegmentedDataSource {

    let loading = AppStoreLoadingDataSource()
    let page = AppStoreFeaturedPageDataSource()

    // reload data on index change
    override var selectedDataSourceIndex: Int {
        didSet {
            ds_reusableViewDelegate?.ds_reloadData()
        }
    }

    override init() {
        super.init()
        loading.items = [Void()] // we add 1 element to show the loading, 2 elements will show it twice. 0 will not show it.

        add(loading)
        add(page)
    }
}
```

5. Register cells.
```Swift
tableView.ds_register(cellNib: AppStoreFeaturedSectionTableViewCell.self)
tableView.ds_register(cellNib: AppStoreQuickLinkLabelTableViewCell.self)
tableView.ds_register(cellNib: AppStoreQuickLinkTableViewCell.self)
tableView.ds_register(cellNib: AppStoreFooterTableViewCell.self)
tableView.ds_register(cellNib: AppStoreLoadingTableViewCell.self)
```

6. Set data sources to the collection view.
```Swift
tableView.ds_useDataSource(dataSource)
```

7. Set the data when it is available.
```Swift
  // show loading indicator
  dataSource.selectedDataSourceIndex = 0

  // get the data from the service
  service.getFeaturedPage { [weak self] page in

    // update the data source model
    self?.dataSource.page.page = page

    // show the page
    self?.dataSource.selectedDataSourceIndex = 1
}
```

There are many benefits of doing that:

1. Lightweight view controllers.
2. You don't need to think about indexes anymore, all is handled for us. Only think about how you can structure your cells into smaller data sources.
3. We can switch between `UITableView` and `UICollectionView` without touching data sources or models. Only change the cells to inherit from `UITableViewCell` or `UICollectionViewCell` and everything else works.
4. We can add/delete/update cells easily. For example we decided to add more blue links. We can do it by just adding new item to the array passed to the data source.
5. We can re-arrange cells as we want. Just move around the `add` of data sources calls.
6. Most importantly no `if`/`else` in our code.



Check the Examples application for complete implementations.

## Attribution

The main idea comes from [WWDC 2014 Advanced User Interfaces with Collection Views] (https://developer.apple.com/videos/play/wwdc2014/232/)
written in swift with generics.

## Author

Mohamed Afifi, mohamede1945@gmail.com

## License

GenericDataSource is available under the MIT license. See the LICENSE file for more info.
