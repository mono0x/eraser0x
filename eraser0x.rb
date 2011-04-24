# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'json'
require 'twitter'
require 'userstream'

PATTERN = Regexp.union([
  /☆/,
  /消し(?:ゴム|ごむ)/,
  /fav/,
  /mono/i,
  /ふぁぼ/,
  /黄色/,
  /サンダース/,
  /\(＃＾ω＾\)/,
])

config = JSON.parse(open('config.json').read)

account = config['account']
oauth   = config['oauth']

Twitter.configure do |c|
  c.consumer_key       = oauth['consumer_key']
  c.consumer_secret    = oauth['consumer_secret']
  c.oauth_token        = oauth['oauth_token']
  c.oauth_token_secret = oauth['oauth_token_secret']
end

consumer = OAuth::Consumer.new(
  oauth['consumer_key'],
  oauth['consumer_secret'],
  :site => 'https://userstream.twitter.com/')

access_token = OAuth::AccessToken.new(
  consumer,
  oauth['oauth_token'],
  oauth['oauth_token_secret'])

userstream = Userstream.new(consumer, access_token)
userstream.user do |status|
  case
  when status.event == 'follow'
    if status.source.screen_name != account
      unless Twitter.friendship_exists?(account, status.source.screen_name)
        Twitter.follow status.source.id
      end
    end
  when status.text
    break unless status.text =~ PATTERN
    unless Twitter.friendship_exists?(status.user.screen_name, account)
      Twitter.unfollow status.user.id
      break
    end
    Twitter.favorite_create status.id
  end
end

