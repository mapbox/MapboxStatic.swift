use_frameworks!

#def shared_pods
#end
#
#target 'MapboxStatic' do
#  shared_pods
#end

def shared_test_pods
  pod 'OHHTTPStubs/Swift', '~> 5.2', :configurations => ['Debug']
end

target 'MapboxStaticTests' do
  platform :ios, '8.0'
  shared_test_pods
end

target 'MapboxStaticMacTests' do
  platform :osx, '10.10'
  shared_test_pods
end

target 'MapboxStaticTVTests' do
  platform :tvos, '9.0'
  shared_test_pods
end
