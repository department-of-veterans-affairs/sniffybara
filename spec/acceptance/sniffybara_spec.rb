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
          <main>
            <h1>I'm the most accessible page in the universe</h1>
            <a id="inaccessible-link" href="/inaccessible">Inaccessible</a>
          </main>
        </body>
      <html>
    }
  end

  get '/inaccessible' do
    %Q{
      <html lang="en">
        <head><title>Accessible page</title></head>
        <body>
          <main>
            <h1>I'm the most accessible page in the universe</h1>
            <a id="inaccessible-link" href="/inaccessible">Inaccessible</a>
            <img src="hello.png" class="test"></img>
          </main>
        </body>
      <html>
    }
  end
end

Capybara.app = TestApp.new
Capybara.current_driver = :sniffybara

describe "Sniffybara" do
  include Capybara::DSL
  before(:each) do
    # Reset axe configuration
    page.evaluate_script <<-EOS
      window.axe = null;
    EOS
  end

  it "doesn't raise error when page is accessible" do
    expect{ visit '/accessible' }.to_not raise_error
  end

  it "raises error when page isn't accessible after visit" do
    expect { visit '/inaccessible' }.to raise_error(Sniffybara::PageNotAccessibleError)
  end

  it "raises error when page isn't accessible after click" do
    visit '/accessible'
    expect { click_link "Inaccessible" }.to raise_error(Sniffybara::PageNotAccessibleError)
  end

  it "allows excpetions" do
    Sniffybara::Driver.issue_id_exceptions << "image-alt"
    expect { visit '/inaccessible#1' }.to_not raise_error
    Sniffybara::Driver.issue_id_exceptions = nil
  end

  it "allows configuration from a json file" do
    Sniffybara::Driver.configuration_file = File.expand_path("spec/support/sample-axe-config.json")
    expect { visit '/inaccessible#2' }.to_not raise_error
    Sniffybara::Driver.configuration_file = nil
  end

  it "doesn't raise error when page matches filter_out pattern" do
    Sniffybara::Driver.path_exclusions << /inaccessible/
    expect { visit '/inaccessible#3' }.to_not raise_error
    Sniffybara::Driver.path_exclusions = nil
  end

  it "allows run configuration from a json file" do
    Sniffybara::Driver.run_configuration_file = File.expand_path("spec/support/sample-axe-run-config.json")
    expect { visit '/inaccessible#4' }.to_not raise_error
    Sniffybara::Driver.run_configuration_file = nil
  end
end
