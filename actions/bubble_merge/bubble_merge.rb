#!/usr/bin/env ruby

require "json"
require "octokit"

require File.join(File.dirname(__FILE__), "git_client")

puts "Bubble merge"

git = Squiddy::GitClient.new

puts "Branch name: #{git.branch}"
puts "Raw event: #{git.raw_event}"
puts "Event path contents: #{git.event}"
