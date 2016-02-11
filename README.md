# Sniffybara

Effortlessly sniff your web application for accessibility issues!  

Sniffybara is a modified [Poltergeist](https://github.com/teampoltergeist/poltergeist) driver for [Capybara](https://github.com/jnicklas/capybara) that scans for 508 accessibility compliance between steps. It uses the [HTML CodeSniffer](https://github.com/squizlabs/HTML_CodeSniffer) to perform accessibility checks.

## Installation

Sniffybara is not hosted in RubyGems.org right now. In the meantime, import it via git by adding the following file to your `Gemfile`

```
gem 'sniffybara', git: 'https://github.com:department-of-veterans-affairs/sniffybara.git'
```

Then install the gems:

> $ bundle install

Because Poltergeist uses the headless browser, PhantomJS, you'll need to install that as well

> $ brew install phantomjs

Then, for any files you'd like to be checked for accessibility add the following lines to the top of that file.

```
require "capybara"
Capybara.current_driver = :sniffybara
```

## Configuration

If you want any accessibility errors to not raise an error, just add them to the exceptions:

```
Sniffybara::Driver.accessibility_code_exceptions << "WCAG2AA.Principle1.Guideline1_3.1_3_1.F68"
```


## Contributing

If you're interested in contributing, or have ideas We'd love for you to help! Leave a github issue on the repository or contact @shanear. 