# frozen_string_literal: true
require "pty"
require 'io/console'

# Signal.trap("INT") {
#   puts "CTRL+C detected, press second time to exit"
#   exit if $ctrl_c
#   $ctrl_c = true
# }

module Runcmd
  module Cli
    class PlayCommand < Clamp::Command
      parameter "RECORDING", "recording"
      option ["--speed", "-"], "SPEED", "speed", default: 0.1 do |s|
        Float(s)
      end

      def execute
        recording_input = File.new recording, "r"
        cmd = recording_input.readline
        args = recording_input.readline.split(" ")

        stderr_reader, stderr_writer = IO.pipe

        env = {
          "LINES" => IO.console.winsize.first.to_s,
          "COLUMNS" => IO.console.winsize.last.to_s
        }

        stdout,stdin,pid = PTY.spawn(env, cmd, *args, err: stderr_writer.fileno)
        stderr_writer.close

        stdin_thr = Thread.new do
          while c = recording_input.getc
            case c
            when "\u0003"
              # control+c
              stdin.print c
            else
              stdin.print c
            end
            sleep speed
          end

          stdin.close
        end

        stdout_thr = Thread.new do
          while c = stdout.getc
            print c
          end
        end

        stderr_thr = Thread.new do
          while c = stderr_reader.getc
            print c
          end
        end

        stdout_thr.join
        stdin_thr.kill

        stdin_thr.join
        stderr_thr.join

        recording_input.close
      end
    end
  end
end
