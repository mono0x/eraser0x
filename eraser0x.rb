# -*- coding: utf-8 -*-

require 'bundler'
Bundler.require

root = File.dirname(__FILE__)
$:.unshift File.join(root, 'lib')

require 'eraser'

Eraser::Database.connect

app = Eraser::Application.new
app.run

