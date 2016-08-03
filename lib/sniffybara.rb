require "capybara"
require 'capybara/poltergeist'
require 'rainbow'


module Sniffybara
  class PageNotAccessibleError < StandardError; end

  module NodeOverrides
    def click
      super
      Sniffybara::Driver.current_driver.process_accessibility_issues
    end
  end

  class Driver < Capybara::Poltergeist::Driver
    class << self
      attr_accessor :current_driver

      # Codes that won't raise errors
      attr_writer :accessibility_code_exceptions, :path_exclusions
      def accessibility_code_exceptions
        @accessibility_code_exceptions ||= [
          "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.BgImage",
          "WCAG2AA.Principle1.Guideline1_4.1_4_3.G145.BgImage",
          "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Abs"
        ]
      end

      def path_exclusions
        @path_exclusions ||= []
      end
    end

    MESSAGE_TYPES = {
      error: 1,
      warning: 2,
      notice: 3
    }

    def initialize(app, options = {})
      super(app,options)
      puts Rainbow("\nAll visited screens will be scanned for 508 accessibility compliance.").cyan

      Capybara::Poltergeist::Node.prepend(NodeOverrides)
    end

    def htmlcs_source
      File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'vendor/HTMLCS.js')).to_json
    end

    def find_accessibility_issues
      execute_script(
        <<-JS
          var htmlcs = document.createElement('script');
          htmlcs.innerHTML = #{htmlcs_source};
          document.querySelector('head').appendChild(htmlcs);

          window.HTMLCS.process('WCAG2AA', window.document, function() {
            window.sniffResults = window.HTMLCS.getMessages().map(function(msg) {
              return {
                "type": msg.type,
                "code": msg.code,
                "msg": msg.msg,
                "tagName": msg.element.tagName.toLowerCase(),
                "elementId": msg.element.id,
                "elementClass": msg.element.className
              };
            }) || [];
          });
        JS
      );

      # should wait for sniffer to finish via callbacks, but not sure how right now.
      sleep 0.01 until(result = evaluate_script("window.sniffResults"))
      result
    end

    def process_accessibility_issues
      return if Driver.path_exclusions.any? { |p| p =~ current_url }

      issues = find_accessibility_issues

      accessibility_error = format_accessibility_issues(issues)
      fail PageNotAccessibleError.new(accessibility_error) unless accessibility_error.empty?
    end

    def format_accessibility_issues(issues)
      issues.inject("") do |result, issue|
        next result if issue["type"] == MESSAGE_TYPES[:notice]
        next result if Sniffybara::Driver.accessibility_code_exceptions.include?(issue["code"])
  
        result += "<#{issue["tagName"]}"
        result += (issue["elementClass"] || "").empty? ? "" : " class='#{issue["elementClass"]}'"
        result += (issue["elementId"] || "").empty? ? ">\n" : " id='#{issue["elementId"]}'>\n"
        result += "#{issue["code"]}\n"
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
  
  # without the --disk-cache option enabled, 304 responses show up as blank HTML documents
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, :phantomjs_options => ['--disk-cache=true'])
end
