$: << 'lib'
require 'bundler/setup'
require 'travis/test-results/app'
run Travis::TestResults::App.new
