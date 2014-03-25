Pod::Spec.new do |s|
  s.name             = "CoreDataHelper"
  s.version          = "0.3.0"
  s.summary          = "A series of helper methods for managing your core data context as well as selecting, inserting, deleting, and sorting"
  s.license          = 'MIT'
  s.author           = { "Daniel Bowden" => "github@bowden.in" }
  s.source           = { :git => "https://github.com/danielbowden/CoreDataHelper.git", :tag => s.version.to_s }

  s.platform     = :ios, '5.0'
  s.ios.deployment_target = '5.0'
  s.requires_arc = true

  s.source_files = 'Classes'

  s.public_header_files = 'Classes/*.h'
end
