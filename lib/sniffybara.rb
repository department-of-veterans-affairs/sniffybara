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
      attr_writer :issue_id_exceptions, :path_exclusions
      def issue_id_exceptions
        @issue_id_exceptions ||= [
          "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.BgImage",
          "WCAG2AA.Principle1.Guideline1_4.1_4_3.G145.BgImage",
          "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Abs"
        ]
      end

      def path_exclusions
        @path_exclusions ||= []
      end
    end

    def initialize(app, options = {})
      super(app,options)
      puts Rainbow("\nAll visited screens will be scanned for 508 accessibility compliance.").cyan

      Capybara::Poltergeist::Node.prepend(NodeOverrides)
    end

    def htmlcs_source
      File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'vendor/HTMLCS.js')).to_json
    end

    def axe_source
      File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'vendor/axe.min.js')).to_json
    end

    def find_accessibility_issues
      execute_script(
        <<-JS
          var axeContainer = document.createElement('script');
          axeContainer.innerHTML = #{axe_source};
          document.querySelector('head').appendChild(axeContainer);

          window.axe.a11yCheck(window.document, function(results) {
            window.sniffResults = results["violations"];
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

    def blocking?(issue)
      !["moderate", "serious", "critical"].include?(issue["impact"])
    end

    def format_accessibility_issues(issues)
      issues.inject("") do |result, issue|
        next result if blocking?(issue)
        next result if Sniffybara::Driver.issue_id_exceptions.include?(issue["id"])


        result += "#{issue["help"]}\n\n"

        result += "Elements:\n"
        issue["nodes"].each do |node|
          result += "#{node["html"]}\n"
          result += "#{node["target"]}\n\n"
        end

        result += "Issue ID: #{issue["id"]}\n\n"

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
