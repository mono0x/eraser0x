# -*- coding: utf-8 -*-

require 'bundler'
Bundler.require :default, :test

SimpleCov.start

$:.unshift "#{File.dirname(__FILE__)}/../lib"

Dir.chdir "#{File.dirname(__FILE__)}/.."
ENV['DATABASE_URL'] = 'sqlite3::memory:'

require 'eraser'
require_relative 'factories'

Eraser::Database.connect.migrate!

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
