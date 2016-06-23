Pod::Spec.new do |s|
  s.name             = "SlateURI"
  s.version          = "3.4.2.1"
  s.summary          = "A uri mechanism."
  s.description      = <<-DESC
			A uri mechanism. Your can custom your own uri format. 
                       DESC
  s.homepage         = "https://github.com/islate/SlateURI"
  s.license          = 'Apache 2.0'
  s.author           = { "linyize" => "linyize@gmail.com" }
  s.source           = { :git => "https://github.com/islate/SlateURI.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'

  s.source_files = 'SlateURI/*.{h,m}'
  
  s.dependency 'SlateUtils'
end
