platform :ios, '9.0'
use_frameworks!
swift_version = "4.0"

target 'VFoundation' do
    pod 'PromiseKit'
    pod 'SwiftyJSON'
    pod 'RxSwift'
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
    pod 'RxSwift'
    pod 'RxCocoa'
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
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'Popover.OC', :git => "git@github.com:mohamede1945/Popover.git" # Added modifications that we need to allow to control direction of the arrow. 
end

target 'QuranTests' do

    pod 'Zip'
    pod 'Moya'
    pod 'PromiseKit'
    pod 'KVOController'
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'SQLite.swift', :inhibit_warnings => true
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
