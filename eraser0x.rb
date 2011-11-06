# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'json'
require 'twitter'
require 'userstream'

PATTERN = Regexp.union([
  /☆|★/,
  /スター/,
  /消し(?:ゴム|ごむ)/,
  /fav/,
  /(?:\A|[^@])mono/i,
  /ふぁぼ/,
  /黄色/,
  /サンダース/,
  /パチリス/,
  /シマリス/,
  /インデント/,
  /\(＃＾ω＾\)/,
  /生首/,
  /test/,
  /放送/,
])

MESSAGES = [
  '( ‘д‘⊂彡☆))Д´) ﾊﾟｰﾝ ',
  '(＃＾ω＾)ﾋﾟｷﾋﾟｷ',
  '＾＾',
  '(＃＾ω＾)ﾎﾟｺﾎﾟｺ イェイ!',
  'ﾁﾝﾁﾝ!! ﾎﾟｺﾎﾟｺ!!',
  '黙れ小僧',
  '期待',
  'bot早く弄れｗｗ',
  '■━⊂( ･∀･) 彡ｶﾞｯ☆( д) ﾟ ﾟ',
  '＜●＞＜●＞',
]

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
      unless Twitter.friendship?(account, status.source.screen_name)
        Twitter.follow status.source.id
      end
    end
  when status.text
    break if status.retweeted_status
    break unless status.text =~ PATTERN
    unless Twitter.friendship?(status.user.screen_name, account)
      Twitter.unfollow status.user.id
      break
    end
    Twitter.favorite_create status.id
    Twitter.retweet status.id
    if rand < 0.05
      Twitter.update(
        "@#{status.user.screen_name} #{MESSAGES[rand MESSAGES.size]}",
        :in_reply_to_status_id => status.id)
    end
  end
end

