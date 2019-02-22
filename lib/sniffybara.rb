require "capybara"
require 'rainbow'

module Sniffybara
  class PageNotAccessibleError < StandardError; end

  module NodeOverrides
    def click(*keys, wait: nil, **offset)
      super
      Sniffybara::Driver.current_driver.process_accessibility_issues
    end
  end

  class Driver < Capybara::Selenium::Driver
    class << self
      attr_accessor :current_driver, :configuration_file

      # Codes that won't raise errors
      attr_writer :issue_id_exceptions, :path_exclusions
      def issue_id_exceptions
        @issue_id_exceptions ||= []
      end

      def path_exclusions
        @path_exclusions ||= []
      end
    end

    def initialize(app, options = {})
      super(app,options)
      puts Rainbow("\nAll visited screens will be scanned for 508 accessibility compliance.").cyan

      Capybara::Selenium::Node.prepend(NodeOverrides)
    end

    def htmlcs_source
      File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'vendor/HTMLCS.js')).to_json
    end

    def axe_source
      File.read(File.join(File.dirname(File.expand_path(__FILE__)), 'vendor/axe.min.js')).to_json
    end

    def configuration_js
      return "" unless Driver.configuration_file && File.exist?(Driver.configuration_file)

      <<-JS
        var axeConfiguration = #{File.read(Driver.configuration_file)}
        window.axe.configure(axeConfiguration);
      JS
    end

    def find_accessibility_issues
      execute_script(
        <<-JS
          if(!window.axe) {
            var axeContainer = document.createElement('script');
            axeContainer.innerHTML = #{axe_source};
            document.querySelector('head').appendChild(axeContainer);

            #{configuration_js}
          }


          window.axe.a11yCheck({exclude: ['iframe']}, function(results) {
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
      return if url_already_scanned?

      issues = find_accessibility_issues

      accessibility_error = format_accessibility_issues(issues)
      fail PageNotAccessibleError.new(accessibility_error) unless accessibility_error.empty?

      record_scanned_url!
    end

    def scanned_urls
      @scanned_urls ||= []
    end

    def url_already_scanned?
      scanned_urls.include?(current_url)
    end

    def record_scanned_url!
      scanned_urls << current_url
    end

    def blocking?(issue)
      ["moderate", "serious", "critical"].include?(issue["impact"])
    end

    def format_accessibility_issues(issues)
      issues.inject("") do |result, issue|
        next result unless blocking?(issue)
        next result if Sniffybara::Driver.issue_id_exceptions.include?(issue["id"])

        result += "#{issue["help"]}\n\n"

        result += "Elements:\n"
        issue["nodes"].each do |node|
          result += "#{node["html"]}\n"
          result += "#{node["target"]}\n\n"
        end

        result += "Issue ID: #{issue["id"]}\n"
        result += "Impact: #{issue["impact"]}\n"
        result += "More Info: #{issue["helpUrl"]}\n\n"
      end
    end

    def visit(path)
      super(path)
      process_accessibility_issues
    end
  end
end

Capybara.register_driver :sniffybara do |app|
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, browser: :chrome)
end
