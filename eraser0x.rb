# -*- coding: utf-8 -*-

require 'bundler/setup'

root = File.dirname(__FILE__)
$:.unshift File.join(root, 'lib')

require 'eraser/application'

app = Eraser::Application.new
app.run

