# frozen_string_literal: true

module Runcmd
  module Cli
    class RootCommand < Clamp::Command
      banner "Run-CMD"

      option ['-v', '--version'], :flag, "Show version information" do
        puts Runcmd::CLI::VERSION
        exit(0)
      end

      subcommand ["version"], "Show version information", VersionCommand
      subcommand ["run"], "run", RunCommand
      subcommand ["play"], "play", PlayCommand

      def self.run
        super
      rescue StandardError => exc
        warn exc.message
        warn exc.backtrace.join("\n")
      end
    end
  end
end
