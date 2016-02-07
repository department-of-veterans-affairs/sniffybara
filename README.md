# Sniffybara

Sniffybara is a modified [Selenium](https://rubygems.org/gems/selenium-webdriver/versions/2.50.0) driver for [Capybara](https://github.com/jnicklas/capybara) that scans for 508 accessibility compliance between steps. It uses the [HTML CodeSniffer](https://github.com/squizlabs/HTML_CodeSniffer) to perform accessibility checks.

## Installation

Sniffybara is not hosted in RubyGems.org right now. In the meantime, import it via git by adding the following file to your `Gemfile`

```
gem 'sniffybara', git: 'git@github.com:department-of-veterans-affairs/sniffybara.git'
```

Then install the gems:

> $ bundle install

Then, for any files you'd like to be checked for accessibility add the following lines to the top of that file.

```
require "capybara"
Capybara.current_driver = :sniffybara
```

## Contributing

If you're interested in contributing, or have ideas We'd love for you to help! Leave a github issue on the repository or contact @shanear. 