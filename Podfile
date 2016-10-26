platform :ios, '8.1'
use_frameworks!

target 'Quran' do

    pod 'GenericDataSources'
    pod 'KVOController-Swift'
    pod 'SQLite.swift', '~> 0.11.0'
    pod 'Zip', '~> 0.6'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'RxSwift'
    pod 'RxCocoa'

    post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
        end
      end
    end
end
