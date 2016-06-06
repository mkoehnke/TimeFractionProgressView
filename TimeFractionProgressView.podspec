Pod::Spec.new do |s|

  s.name         = "TimeFractionProgressView"
  s.version      = "1.1.1"
  s.summary      = "Easy to use iOS view for displaying multiple temporal progress graphs."

  s.description  = <<-DESC
                   Easy to use iOS view for displaying multiple temporal progress graphs, written in Swift. 
		   DESC

  s.homepage     = "https://github.com/mkoehnke/TimeFractionProgressView"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = "Mathias Köhnke"

  s.ios.deployment_target = '8.2'

  s.source       = { :git => "https://github.com/mkoehnke/TimeFractionProgressView.git", :tag => s.version.to_s }

  s.source_files  = "TimeFractionProgressView/*.{swift}"
  s.exclude_files = "Classes/Exclude"

  s.requires_arc = true
end
