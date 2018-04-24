platform :ios, '9.0'
use_frameworks!
swift_version = "4.0"

target 'VFoundation' do
    pod 'PromiseKit', :inhibit_warnings => true
    pod 'SwiftyJSON'
    pod 'RxSwift', :inhibit_warnings => true
    pod 'SwiftLint'
end

target 'SQLitePersistence' do
    pod 'SQLite.swift'
end

target 'BatchDownloader' do
    pod 'PromiseKit', :inhibit_warnings => true
    pod 'SQLite.swift'
end

target 'UIKitExtension' do
    pod 'PromiseKit', :inhibit_warnings => true
    pod 'RxSwift', :inhibit_warnings => true
    pod 'RxCocoa'
end

target 'QueuePlayer' do
    pod 'KVOController'
end

target 'Quran' do

    pod 'GenericDataSources'
    pod 'SQLite.swift'
    pod 'Zip'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'MenuItemKit'
    pod 'Moya'
    pod 'SwiftyJSON'
    pod 'PromiseKit', :inhibit_warnings => true
    pod 'DownloadButton'
    pod 'KVOController'
    pod 'NSDate+TimeAgo'
    pod 'RxSwift', :inhibit_warnings => true
    pod 'RxCocoa'
    pod 'Popover.OC', :git => "git@github.com:mohamede1945/Popover.git" # Added modifications that we need to allow to control direction of the arrow. 
end

target 'QuranTests' do

    pod 'Zip'
    pod 'Moya'
    pod 'PromiseKit', :inhibit_warnings => true
    pod 'KVOController'
    pod 'RxSwift', :inhibit_warnings => true
    pod 'RxCocoa'
    pod 'SQLite.swift'
end

target 'QuranUITests' do
    pod 'SwiftMonkey', :git => "git@github.com:mohamede1945/SwiftMonkey.git" # Added modifications that would allow it to compile
end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        if config.name == 'Release'
            config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
            else
            config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
        end
    end
end
