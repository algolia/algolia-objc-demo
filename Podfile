use_frameworks!

target "MoviesSearch" do
    pod 'AlgoliaSearch-Client-Swift', '~> 3.0'
    pod 'AFNetworking', '~> 3.0'
end

# Enforce Swift 3.
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
