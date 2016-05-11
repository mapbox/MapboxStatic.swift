Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "MapboxStatic.swift"
  s.version      = "0.4.0"
  s.summary      = "Classic Mapbox Static API wrapper for Objective-C and Swift."

  s.description  = <<-DESC
  MapboxStatic.swift makes it easy to connect your iOS, tvOS, or watchOS application to the classic Mapbox Static API. Quickly generate a static map image with overlays, asynchronous imagery fetching, and first-class Swift data types.
                   DESC

  s.homepage     = "https://www.mapbox.com/api-documentation/#static-classic"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license      = { :type => "BSD", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author             = { "Mapbox" => "mobile@mapbox.com" }
  s.social_media_url   = "https://twitter.com/mapbox"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  #  When using multiple platforms
  s.ios.deployment_target = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  #s.source       = { :git => "https://github.com/mapbox/MapboxStatic.swift.git", :tag => "v#{s.version.to_s}" }
  s.source       = { :git => "https://github.com/mapbox/MapboxStatic.swift.git", :tag => "#{s.version.to_s}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "MapboxStatic"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "MapboxStatic"

  #s.dependency "NBNRequestKit"

end
