# -*- coding: utf-8 -*-

require 'data_mapper'

module Eraser
  class Message
    include DataMapper::Resource

    property :id, Serial
    property :text, String, :required => true, :unique => true

    def self.random
      get rand(all.count) + 1
    end
  end
end

DataMapper.finalize
