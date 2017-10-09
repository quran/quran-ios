platform :ios, '9.0'
use_frameworks!
swift_version = "4.0"

target 'VFoundation' do
    pod 'PromiseKit'
    pod 'SwiftyJSON'
    pod 'RxSwift', :git => "git@github.com:ReactiveX/RxSwift.git", :branch => "rxswift4.0-swift4.0" # Until they release it.
    pod 'SwiftLint'
end

target 'SQLitePersistence' do
    pod 'SQLite.swift', :inhibit_warnings => true
end

target 'BatchDownloader' do
    pod 'PromiseKit'
    pod 'SQLite.swift', :inhibit_warnings => true
end

target 'UIKitExtension' do
    pod 'PromiseKit'
    pod 'RxSwift', :git => "git@github.com:ReactiveX/RxSwift.git", :branch => "rxswift4.0-swift4.0" # Until they release it.
    pod 'RxCocoa', :git => "git@github.com:ReactiveX/RxSwift.git", :branch => "rxswift4.0-swift4.0" # Until they release it.
end

target 'QueuePlayer' do
    pod 'KVOController'
end

target 'Quran' do

    pod 'GenericDataSources'
    pod 'SQLite.swift', :inhibit_warnings => true
    pod 'Zip'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'MenuItemKit'
    pod 'Moya'
    pod 'SwiftyJSON'
    pod 'PromiseKit'
    pod 'DownloadButton'
    pod 'KVOController'
    pod 'NSDate+TimeAgo'
    pod 'RxSwift', :git => "git@github.com:ReactiveX/RxSwift.git", :branch => "rxswift4.0-swift4.0" # Until they release it.
    pod 'RxCocoa', :git => "git@github.com:ReactiveX/RxSwift.git", :branch => "rxswift4.0-swift4.0" # Until they release it.
    pod 'Popover.OC', :git => "git@github.com:mohamede1945/Popover.git" # Added modifications that we need to allow to control direction of the arrow. 
end

target 'QuranTests' do

    pod 'Zip'
    pod 'Moya'
    pod 'PromiseKit'
    pod 'KVOController'
    pod 'RxSwift', :git => "git@github.com:ReactiveX/RxSwift.git", :branch => "rxswift4.0-swift4.0" # Until they release it.
    pod 'RxCocoa', :git => "git@github.com:ReactiveX/RxSwift.git", :branch => "rxswift4.0-swift4.0" # Until they release it.
    pod 'SQLite.swift', :inhibit_warnings => true
end

target 'QuranUITests' do
    pod "SwiftMonkey", :inhibit_warnings => true
end
