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
    class RunCommand < Clamp::Command
      parameter "COMMAND ...", "command"
      option ["--record","-r"], "RECORD", "record"

      def execute
        cmd = command_list.shift
        args = command_list

        stderr_reader, stderr_writer = IO.pipe

        env = {
          "LINES" => IO.console.winsize.first.to_s,
          "COLUMNS" => IO.console.winsize.last.to_s
        }

        log = File.new record, "w" if record

        stdout,stdin,pid = PTY.spawn(env, cmd, *args, err: stderr_writer.fileno)
        stderr_writer.close

        stdin_thr = Thread.new do
          while c = $stdin.getch
            case c
            when "\u0003"
              # control+c
              stdin.print c
            else
              stdin.print c
              log.print c if record
            end
          end

          stdin.close
        end

        stdout_thr = Thread.new do
          while c = stdout.getc
            print c
            log.print c if record
          end
        end

        stderr_thr = Thread.new do
          while c = stderr_reader.getc
            print c
            log.print c if record
          end
        end

        stdout_thr.join
        puts "stdout closed"
        stdin_thr.kill

        stdin_thr.join
        puts "stdin closed"
        stderr_thr.join
        puts "stderr closed"

        log.close if record
      end
    end
  end
end
