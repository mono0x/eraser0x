# -*- coding: utf-8 -*-

require 'json'
require 'dm-migrations'

root = File.dirname(__FILE__)
$:.unshift File.join(root, 'lib')

require 'eraser'

namespace :db do
  task :migrate do
    Eraser::Database.connect.migrate!
  end

  task :upgrade do
    Eraser::Database.connect.upgrade!
  end

  task :import, 'file' do |t, a|
    JSON.parse(*open(a.file))['messages'].each do |t|
      Eraser::Message.create :text => t
    end
  end
end
