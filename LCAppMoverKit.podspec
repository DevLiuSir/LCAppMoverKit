Pod::Spec.new do |spec|

  spec.name         = "LCAppMoverKit"

  spec.version      = "1.0.0"
  
  spec.summary      = "LCAppMoverKit is a Non-sandbox lightweight Cocoa framework for detecting and moving running Mac OS X applications to the Applications folder!"
  
  spec.description  = <<-DESC
LCAppMoverKit is a lightweight Cocoa framework for detecting and moving running Mac OS X applications to the Applications folder!
                   DESC
  
  spec.homepage     = "https://github.com/DevLiuSir/LCAppMoverKit"
  
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  
  spec.author                = { "Marvin" => "93428739@qq.com" }
  
  spec.swift_versions        = ['5.0']
  
  spec.platform              = :osx
  
  spec.osx.deployment_target = "10.14"
  
  spec.source       = { :git => "https://github.com/DevLiuSir/LCAppMoverKit.git", :tag => "#{spec.version}" }

  spec.source_files = "Sources/LCAppMoverKit/**/*.{h,m,swift}"
  
  spec.resource     = 'Sources/LCAppMoverKit/Resources/**/*.strings'

end
