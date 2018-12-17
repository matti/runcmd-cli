source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in runcmd-cli.gemspec
gemspec

unless ENV['RUNCMD_USE_RUBYGEMS'] == "yes"
  gem "runcmd", path: "../runcmd"
end
