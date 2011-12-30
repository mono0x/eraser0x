# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'json'
require 'twitter'
require 'userstream'

module Eraser
  class Config
    def self.load(path)
      c = new()
      c.instance_eval open(path).read
      c
    end

    attr_reader :account
    attr_reader :author
    attr_reader :oauth
    attr_reader :pattern
  end
end

messages = JSON.parse(open('messages.json', 'r:utf-8').read)['messages']

config = Eraser::Config.load('eraser.conf')

Twitter.configure do |c|
  c.consumer_key       = config.oauth[:consumer_key]
  c.consumer_secret    = config.oauth[:consumer_secret]
  c.oauth_token        = config.oauth[:oauth_token]
  c.oauth_token_secret = config.oauth[:oauth_token_secret]
end

consumer = OAuth::Consumer.new(
  config.oauth[:consumer_key],
  config.oauth[:consumer_secret],
  :site => 'https://userstream.twitter.com/')

access_token = OAuth::AccessToken.new(
  consumer,
  config.oauth[:oauth_token],
  config.oauth[:oauth_token_secret])

Signal.trap :HUP do
  STDERR.puts 'SIGHUP'
  config = Eraser::Config.load('eraser.conf')
end

userstream = Userstream.new(consumer, access_token)
userstream.user do |status|
  STDERR.puts status.inspect
  case
  when status.event == 'follow'
    if status.source.screen_name != config.account
      unless Twitter.friendship?(config.account, status.source.screen_name)
        Twitter.follow status.source.id
      end
    end
  when status.event == 'favorite'
    next if status.source.screen_name == config.account
    next unless Twitter.friendship?(status.source.screen_name, config.account)
    timeline = Twitter.user_timeline(status.source.screen_name).select {|s|
      !s.retweeted_status && !s.in_reply_to_status_id && !s.favorited
    }
    next if timeline.empty?
    target = timeline[rand timeline.size]
    begin
      Twitter.favorite_create target.id
      Twitter.retweet target.id
    rescue
    end
  when status.direct_message
    if status.direct_message.sender_screen_name == config.author
      Twitter.update status.direct_message.text
    end
  when status.text
    next if status.retweeted_status
    if status.text =~ /\A@#{config.account}\s+(.+)\Z/m
      m = $1.gsub(/[@#]/, '_')
      unless Twitter.friendship?(status.user.screen_name, config.account)
        Twitter.unfollow status.user.id
        next
      end
      unless messages.include?(m)
        messages.push m
        json = { 'messages' => messages }.to_json
        open('messages.json', 'w') do |f|
          f << json
        end
      end
      Twitter.update(
        "@#{status.user.screen_name} #{messages[rand messages.size]}",
        :in_reply_to_status_id => status.id)
      next
    end
    next unless status.text =~ config.pattern
    unless Twitter.friendship?(status.user.screen_name, config.account)
      Twitter.unfollow status.user.id
      next
    end
    Twitter.favorite_create status.id
    Twitter.retweet status.id
    if rand < 0.05
      Twitter.update(
        "@#{status.user.screen_name} #{messages[rand messages.size]}",
        :in_reply_to_status_id => status.id)
    end
  end
end

