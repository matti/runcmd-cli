# frozen_string_literal: true

module Runcmd
  module Cli
    class VersionCommand < Clamp::Command
      def execute
        puts Runcmd::Cli::VERSION
      end
    end
  end
end
