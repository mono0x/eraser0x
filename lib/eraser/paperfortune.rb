# -*- coding: utf-8 -*-

require 'date'
require 'digest/sha1'

module Eraser
  module PaperFortune
    def self.paper_fortune(w, *a)
      n = w.inject(&:+)
      r = Random.new(Digest::SHA1.hexdigest(Marshal.dump(a)).to_i(16)).rand(n)
      w.each_index.find {|i| r < w[0..i].inject(&:+) }
    end
  end
end
