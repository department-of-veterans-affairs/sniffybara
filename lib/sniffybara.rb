require "capybara"
require 'sinatra/base'

module Sniffybara
  class PageNotAccessibleError < StandardError; end

  # Serves the HTMLCS source file to be dynamically loaded into the page
  class AssetServer < Sinatra::Application
    PORT = 9006
    set :port, PORT

    def path_to_htmlcs
      File.join(File.dirname(File.expand_path(__FILE__)), 'vendor/HTMLCS.js')
    end

    get '/htmlcs.js' do
      send_file path_to_htmlcs
    end
  end

  class Driver < Capybara::Selenium::Driver
    MESSAGE_TYPES = {
      error: 1,
      warning: 2,
      notice: 3
    }

    def initialize(*args)
      super(args)
      puts Rainbow("\nAll visited screens will be scanned for 508 accessibility compliance.").cyan

      Thread.new do
        AssetServer.run!    
      end
    end

    def find_accessibility_issues
      execute_script(%Q{
        var htmlcs = document.createElement('script');
        htmlcs.src = "http://localhost:#{Sniffybara::AssetServer::PORT}/htmlcs.js";
        htmlcs.async = true;
        htmlcs.onreadystatechange = htmlcs.onload = function() {
          window.HTMLCS.process('WCAG2AAA', window.document, function() {
            window.sniffResults = window.HTMLCS.getMessages();
          });
        };
        document.querySelector('head').appendChild(htmlcs);
      });

      result = evaluate_script("window.sniffResults") || []
      result
    end

    def process_accessibility_issues(issues)
      issues.each do |issue|
        if issue["type"] == MESSAGE_TYPES[:error] || issue["type"] == MESSAGE_TYPES[:warning]
          fail PageNotAccessibleError.new(format_accessibility_issues(issues))
        end
      end
    end

    def format_accessibility_issues(issues)
      issues.inject("") do |result, issue|
        next result if issue["type"] == MESSAGE_TYPES[:notice]

        element_id = issue["element"].attribute("id")
        result += "<#{issue["element"].tag_name}"
        result += element_id.empty? ? ">\n" : " id = '#{element_id}'>\n"
        result += "#{issue["msg"]}\n\n"
      end
    end

    def visit(path)
      super(path)
      process_accessibility_issues(find_accessibility_issues)
    end
  end
end

Capybara.register_driver :sniffybara do |app|
  Sniffybara::Driver.new(app)
end