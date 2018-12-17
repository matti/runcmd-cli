require "clamp"
Clamp.allow_options_after_parameters = true

module Runcmd
  module Cli
  end
end

require_relative "cli/version"

require_relative "cli/version_command"
require_relative "cli/record_command"
require_relative "cli/play_command"

require_relative "cli/root_command"
