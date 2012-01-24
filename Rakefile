# -*- coding: utf-8 -*-

require 'json'
require 'dm-migrations'

root = File.dirname(__FILE__)
$:.unshift File.join(root, 'lib')

require 'eraser/models'

DataMapper.setup :default, ENV['DATABASE_URL']

namespace :db do
  task :migrate do
    DataMapper.auto_migrate!
  end

  task :upgrade do
    DataMapper.auto_upgrade!
  end

  task :import, 'file' do |t, a|
    JSON.parse(*open(a.file))['messages'].each do |t|
      Eraser::Message.create :text => t
    end
  end
end
