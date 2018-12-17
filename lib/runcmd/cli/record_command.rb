# frozen_string_literal: true
require "pty"
require 'io/console'

Signal.trap("INT") {
  puts "CTRLC"
  exit if $ctrl_c
  $ctrl_c = true
}

module Runcmd
  module Cli
    class RecordCommand < Clamp::Command
      parameter "RECORDING", "recording"
      parameter "COMMAND ...", "command"

      option ["--video", "-v"], "VIDEO", "video"
      def execute
        cmd = command_list.shift
        args = command_list

        stderr_reader, stderr_writer = IO.pipe

        env = {
          "LINES" => IO.console.winsize.first.to_s,
          "COLUMNS" => IO.console.winsize.last.to_s
        }

        recording_video = File.new "#{recording}.video", "w" if video
        recording_input = File.new "#{recording}.runcmd", "w"
        recording_input.puts cmd
        recording_input.puts args.join(" ")

        stdout,stdin,pid = PTY.spawn(env, cmd, *args, err: stderr_writer.fileno)
        stderr_writer.close

        stdin_thr = Thread.new do
          while c = $stdin.getch
            recording_input.print c
            case c
            when "\u0003"
              # control+c
              stdin.print c
            else
              stdin.print c
            end
          end

          stdin.close
        end

        stdout_thr = Thread.new do
          while c = stdout.getc
            print c
            recording_video.print c if video
          end
        end

        stderr_thr = Thread.new do
          while c = stderr_reader.getc
            print c
            recording_video.print c if video
          end
        end

        stdout_thr.join
        stdin_thr.kill

        stdin_thr.join
        stderr_thr.join

        recording_video.close if video
        recording_input.close

      end
    end
  end
end
