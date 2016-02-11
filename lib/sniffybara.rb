require "capybara"
require 'capybara/poltergeist'
require 'rainbow'
require 'sinatra/base'


module Sniffybara
  class PageNotAccessibleError < StandardError; end

  # Serves the HTMLCS source file to be dynamically loaded into the page
  class AssetServer < Sinatra::Application
    PORT = 9006
    set :port, PORT
    set :logging, false

    def path_to_htmlcs
      File.join(File.dirname(File.expand_path(__FILE__)), 'vendor/HTMLCS.js')
    end

    get '/htmlcs.js' do
      send_file path_to_htmlcs
    end
  end

  module NodeOverrides
    def click
      super
      Sniffybara::Driver.current_driver.process_accessibility_issues
    end
  end

  class Driver < Capybara::Poltergeist::Driver
    class << self
      attr_accessor :current_driver
    end

    MESSAGE_TYPES = {
      error: 1,
      warning: 2,
      notice: 3
    }

    def initialize(*args)
      super(args)
      puts Rainbow("\nAll visited screens will be scanned for 508 accessibility compliance.").cyan

      Capybara::Poltergeist::Node.prepend(NodeOverrides)

      Thread.new do
        AssetServer.run!    
      end
    end

    def find_accessibility_issues
      execute_script(
        <<-JS
          var htmlcs = document.createElement('script');
          htmlcs.src = "http://localhost:#{Sniffybara::AssetServer::PORT}/htmlcs.js";
          htmlcs.async = true;
          htmlcs.onreadystatechange = htmlcs.onload = function() {
            window.HTMLCS.process('WCAG2AA', window.document, function() {
              window.sniffResults = window.HTMLCS.getMessages().map(function(msg) {
                return {
                  "type": msg.type,
                  "msg": msg.msg,
                  "tagName": msg.element.tagName.toLowerCase(),
                  "elementId": msg.element.id,
                  "elementClass": msg.element.className
                };
              }) || [];
            });
          };
          document.querySelector('head').appendChild(htmlcs);
        JS
      );

      # should wait for sniffer to finish via callbacks, but not sure how right now.
      sleep 0.01 until(result = evaluate_script("window.sniffResults"))
      result
    end

    def process_accessibility_issues
      issues = find_accessibility_issues

      issues.each do |issue|
        if issue["type"] == MESSAGE_TYPES[:error] || issue["type"] == MESSAGE_TYPES[:warning]
          fail PageNotAccessibleError.new(format_accessibility_issues(issues))
        end
      end
    end

    def format_accessibility_issues(issues)
      issues.inject("") do |result, issue|
        next result if issue["type"] == MESSAGE_TYPES[:notice]
  
        result += "<#{issue["tagName"]}"
        result += (issue["elementClass"] || "").empty? ? "" : " class='#{issue["elementClass"]}'"
        result += (issue["elementId"] || "").empty? ? ">\n" : " id='#{issue["elementId"]}'>\n"
        result += "#{issue["msg"]}\n\n"
      end
    end

    def visit(path)
      super(path)
      process_accessibility_issues
    end
  end
end

Capybara.register_driver :sniffybara do |app|
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app)
end