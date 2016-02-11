require 'sinatra'
require 'sinatra/base'
require 'capybara'
require 'capybara/dsl'
require 'sniffybara'

class TestApp < Sinatra::Application
  set :logging, false

  get '/accessible' do
    %q{
      <html lang="en">
        <head><title>Accessible page</title></head>
        <body>
          <h1>I'm the most accessible page in the universe</h1>
          <a id="inaccessible-link" href="/inaccessible">Inaccessible</a>
        </body>
      <html>
    }
  end

  get '/inaccessible' do
    %Q{
      <html lang="en">
        <head><title>Accessible page</title></head>
        <body>
          <h1>I'm the most accessible page in the universe</h1>
          <a id="inaccessible-link" href="/inaccessible">Inaccessible</a>
          <img src="hello.png" class="test"></img>
        </body>
      <html>
    }
  end
end

Capybara.app = TestApp.new
Capybara.current_driver = :sniffybara

describe "Sniffybara" do
  include Capybara::DSL
  
  it "doesn't raise error when page is accessible" do
    expect{ visit '/accessible' }.to_not raise_error
  end

  it "raises error when page isn't accessible after visit" do
    expect { visit '/inaccessible' }.to raise_error(Sniffybara::PageNotAccessibleError)
  end

  it "raises error when page isn't accessible after click" do
    visit '/accessible'
    expect { click_on "Inaccessible" }.to raise_error(Sniffybara::PageNotAccessibleError)
  end

  it "allows excpetions" do
    Sniffybara::Driver.accessibility_code_exceptions << "WCAG2AA.Principle1.Guideline1_1.1_1_1.H37"
    expect { visit '/inaccessible' }.to_not raise_error
    Sniffybara::Driver.accessibility_code_exceptions = nil
  end
end