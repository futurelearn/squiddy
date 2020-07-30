#!/usr/bin/env ruby

require "json"
require "octokit"

require File.join(File.dirname(__FILE__), "git_client")

puts "Bubble merge"

git = Squiddy::GitClient.new

git.bubble_merge
