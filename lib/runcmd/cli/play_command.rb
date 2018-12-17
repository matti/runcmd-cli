# frozen_string_literal: true

module Runcmd
  module Cli
    class PlayCommand < Clamp::Command
      parameter "RECORDING", "recording"
      option ["--speed", "-s"], "speed", "speed", default: 0 do |s|
        Float(s)
      end

      def execute
        log = File.open(recording, "r")
        log.each_char do |c|
          print c
          sleep speed
        end
      end
    end
  end
end
