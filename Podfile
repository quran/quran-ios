platform :ios, '9.0'
use_frameworks!
swift_version = "4.0"

def promise_kit
    pod 'PromiseKit', '~> 6.5', :inhibit_warnings => true
end
def swifty_json
    pod 'SwiftyJSON', '~> 4.1'
end
def rx_swift
    pod 'RxSwift', '~> 4.3', :inhibit_warnings => true
end
def rx_cocoa
    pod 'RxCocoa', '~> 4.3'
end
def swift_lint
    pod 'SwiftLint', '~> 0.27'
end
def sqlite
    pod 'SQLite.swift', '~> 0.11'
end
def kvo_controller
    pod 'KVOController', '~> 1.2'
end
def generic_data_sources
    pod 'GenericDataSources', '~> 3.0'
end
def zip
    pod 'Zip', '~> 1.1'
end
def fabric
    pod 'Fabric', '~> 1.7'
end
def crashlytics
    pod 'Crashlytics', '~> 3.10'
end
def menu_item_kit
    pod 'MenuItemKit', '~> 3.1'
end
def moya
    pod 'Moya', '~> 11.0', :inhibit_warnings => true
end
def download_button
    pod 'DownloadButton', '~> 0.1'
end
def nsdate_time_ago
    pod 'NSDate+TimeAgo', '~> 1.0'
end
def popover_oc
    pod 'Popover.OC', :git => "git@github.com:mohamede1945/Popover.git" # Added modifications that we need to allow to control direction of the arrow.
end
def nimble
    pod 'Nimble', '~>  7.3'
end
def quick
    pod 'Quick', '~>  1.3'
end
def ribs
    pod 'RIBs', '~> 0.9', :inhibit_warnings => true
end
def swift_monkey
    pod 'SwiftMonkey', :git => "git@github.com:mohamede1945/SwiftMonkey.git" # Added modifications that would allow it to compile
end

target 'VFoundation' do
    promise_kit
    swifty_json
    rx_swift
    swift_lint
end

target 'SQLitePersistence' do
    sqlite
end

target 'BatchDownloader' do
    promise_kit
    sqlite
end

target 'UIKitExtension' do
    promise_kit
    rx_swift
    rx_cocoa
end

target 'QueuePlayer' do
    kvo_controller
end

target 'Quran' do
    generic_data_sources
    sqlite
    zip
    fabric
    crashlytics
    menu_item_kit
    moya
    swifty_json
    promise_kit
    download_button
    kvo_controller
    nsdate_time_ago
    rx_swift
    rx_cocoa
    popover_oc
    ribs
end

target 'QuranTests' do
    zip
    moya
    promise_kit
    kvo_controller
    rx_swift
    rx_cocoa
    sqlite
    nimble
    quick
end

target 'QuranUITests' do
    swift_monkey
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
