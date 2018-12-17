# frozen_string_literal: true
require "pty"
require 'io/console'

module Runcmd
  module Cli
    class PlayCommand < Clamp::Command
      parameter "RECORDING", "recording"
      option ["--delay"], "DELAY", "extra delay", default: 0.0 do |s|
        Float(s)
      end

      def execute
        recording_input = File.new recording, "r"
        version = recording_input.readline
        cmd = recording_input.readline
        args = recording_input.readline.split(" ")

        stderr_reader, stderr_writer = IO.pipe

        env = {
          "LINES" => IO.console.winsize.first.to_s,
          "COLUMNS" => IO.console.winsize.last.to_s
        }

        stdout,stdin,pid = PTY.spawn(env, cmd, *args, err: stderr_writer.fileno)
        stderr_writer.close

        started_at = Time.now
        stdin_thr = Thread.new do
          while c = recording_input.getc
            time = []
            loop do
              t = recording_input.getc
              break if t == ":"
              time << t
            end
            sleep time.join("").to_f
            case c
            when "\u0003"
              # control+c
              stdin.print c
            else
              stdin.print c
            end
            sleep delay
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
