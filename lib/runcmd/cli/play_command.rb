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
        recording_path = if recording.end_with? ".runcmd"
          recording
        else
          "#{recording}.runcmd"
        end

        unless File.exist? recording_path
          $stderr.puts "File #{recording_path} does not exist."
          exit 1
        end

        recording_input = File.new recording_path, "r"
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
          loop do
            command = recording_input.getc
            case command
            when "c"
              c = recording_input.getc
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
            when "a"
              assert_chars = []
              loop do
                assert_c = recording_input.getc
                case assert_c
                when "\u0003"
                  break
                else
                  assert_chars << assert_c
                end
              end

              assert_string = assert_chars.join("")

              loop do
                # print "\033[s" #save cursor
                # print "\033[0;0f" #move to top left
                # print "\033[K" #erase current line
                # print "\e[36m" #cyan
                # print "Run-CMD> waiting for: #{assert_string}"
                # print "\e[0m" #reset
                # print "\033[u" #restore cursor

                if $output.join("").match? assert_string
                  $output = []
                  break
                end

                sleep 0.1
              end

              # print "\033[s" #save cursor
              # print "\033[0;0f" #move to top left
              # print "\033[K" #erase current line
              # print "\033[u" #restore cursor
            end
          end

          stdin.close
        end

        $output = []
        stdout_thr = Thread.new do
          while c = stdout.getc
            $output << c
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
