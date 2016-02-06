require 'sinatra'
require 'sinatra/base'
require 'capybara'
require 'capybara/dsl'
require 'sniffybara'

class TestApp < Sinatra::Application
  get '/accessible' do
    %q{
      <html lang="en">
        <head><title>Accessible page</title></head>
        <body>
          <h1>I'm the most accessible page in the universe</h1>
        </body>
      <html>
    }
  end

  get '/inaccessible' do
    %Q{
      <html>
      <body>
      Hello there
        <input type="text"></input>
        <img src="hello.png"></img>
      </body>
      </html>
    }
  end
end

describe "Sniffybara" do
  include Capybara::DSL

  before do
    Capybara.app = TestApp.new
    Capybara.current_driver = :sniffybara
  end
  
  it "doesn't raise error when page is accessible" do
    expect{ visit '/accessible' }.to_not raise_error
  end

  it "raises error when page isn't accessible" do
    expect { visit '/inaccessible' }.to raise_error(Sniffybara::PageNotAccessibleError)
  end
end