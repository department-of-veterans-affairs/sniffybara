Gem::Specification.new do |s|
  s.name        = "sniffybara"
  s.version     = "0.0.1"
  s.date        = "2016-02-05"
  s.summary     = "Capybara accessibility extention"
  s.description = "Selenium driver for Capybara that checks for 508 Accessibility compliance with HTML CodeSniffer."
  s.authors     = ["Shane Russell"]
  s.email       = "shane1337@gmail.com"
  s.files       = ["lib/sniffybara.rb"]
  s.homepage    = ""
  s.license       = ""

  s.add_runtime_dependency "selenium-webdriver"
  s.add_runtime_dependency "rainbow"
  s.add_runtime_dependency "poltergeist"

  s.add_development_dependency "capybara"
  s.add_development_dependency "rspec"
  s.add_development_dependency "sinatra"
end
