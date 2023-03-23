Gem::Specification.new do |s|
  s.name        = "sniffybara"
  s.version     = "1.1.0"
  s.date        = "2019-11-13"
  s.summary     = "Capybara accessibility extention"
  s.description = "Selenium driver for Capybara that uses the Axe accessibility testing engine v3.0.4"
  s.authors     = ["Shane Russell", "Alisa Nguyen"]
  s.email       = "alisanguyen@navapbc.com"
  s.files       = ["lib/sniffybara.rb"]
  s.homepage    = ""
  s.license       = ""

  s.add_runtime_dependency "selenium-webdriver", "~> 4.8.1"
  s.add_runtime_dependency "rainbow"

  s.add_development_dependency "capybara"
  s.add_development_dependency "rspec"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "webdrivers"
  s.add_development_dependency "puma"
end
