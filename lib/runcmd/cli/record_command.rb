# frozen_string_literal: true
require "pty"
require 'io/console'

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
        recording_input.puts Runcmd::Cli::VERSION
        recording_input.puts cmd
        recording_input.puts args.join(" ")

        stdout,stdin,pid = PTY.spawn(env, cmd, *args, err: stderr_writer.fileno)
        stderr_writer.close

        stdin_thr = Thread.new do
          loop do
            started_at = Time.now
            c = $stdin.getch
            #p c

            case c
            when "\u0010"
              print "\033[s" #save cursor
              print "\033[0;0f" #move to top left
              print "\033[K" #erase current line
              print "\e[36m" #cyan
              print "Run-CMD> wait_for: "
              print "\e[0m" #reset

              assert_string = []
              loop do
                assert_c = $stdin.getch
                case assert_c
                when "\u007F"
                  next if assert_string.empty?

                  assert_string.pop
                  $stdout.print "\b"
                  $stdout.print "\033[K"
                when "\f"
                  stdin.write "\x1B\x1Bl" # send it forward
                  break
                when "\r"
                  $stdout.print "\r"
                  $stdout.print "\033[K"
                  break
                when "\e"
                  $stdin.getch
                  $stdin.getch
                  next
                else
                  assert_string << assert_c
                  $stdout.print assert_c
                end
              end

              recording_input.print 'a'
              recording_input.print assert_string.join("")
              recording_input.print "\u0003"

              print "\033[u" #restore cursor
            else
              recording_input.print 'c'
              recording_input.print c
              recording_input.print (Time.now-started_at).floor(2)
              recording_input.print ':'

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
