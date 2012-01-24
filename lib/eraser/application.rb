# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'twitter'
require 'userstream'

require 'eraser/models'

DataMapper.setup :default, ENV['DATABASE_URL']

module Eraser
  class Application
    def run
      twitter = ::Twitter::Client.new(
        :consumer_key       => ENV['TWITTER_CONSUMER_KEY'],
        :consumer_secret    => ENV['TWITTER_CONSUMER_SECRET'],
        :oauth_token        => ENV['TWITTER_OAUTH_TOKEN'],
        :oauth_token_secret => ENV['TWITTER_OAUTH_TOKEN_SECRET'])

      consumer = ::OAuth::Consumer.new(
        ENV['TWITTER_CONSUMER_KEY'],
        ENV['TWITTER_CONSUMER_SECRET'],
        :site => 'https://userstream.twitter.com/')

      access_token = ::OAuth::AccessToken.new(
        consumer,
        ENV['TWITTER_OAUTH_TOKEN'],
        ENV['TWITTER_OAUTH_TOKEN_SECRET'])

      userstream = ::Userstream.new(consumer, access_token)
      userstream.user do |status|
        STDERR.puts status.inspect
        case
        when status.event == 'follow'
          if status.source.screen_name != ENV['ACCOUNT']
            unless twitter.friendship?(ENV['ACCOUNT'], status.source.screen_name)
              twitter.follow status.source.id
            end
          end
        when status.event == 'favorite'
          next if status.source.screen_name == ENV['ACCOUNT']
          next unless twitter.friendship?(status.source.screen_name, ENV['ACCOUNT'])
          timeline = twitter.user_timeline(status.source.screen_name).select {|s|
            !s.retweeted_status && !s.in_reply_to_status_id && !s.favorited
          }
          next if timeline.empty?
          target = timeline[rand timeline.size]
          begin
            twitter.favorite_create target.id
            twitter.retweet target.id
          rescue
          end
        when status.direct_message
          if status.direct_message.sender_screen_name == ENV['AUTHOR']
            twitter.update status.direct_message.text
          end
        when status.text
          next if status.retweeted_status
          if status.text =~ /\A@#{ENV['ACCOUNT']}\s+(.+)\Z/m
            m = $1.gsub(/[@#]/, '_')
            unless twitter.friendship?(status.user.screen_name, ENV['ACCOUNT'])
              twitter.unfollow status.user.id
              next
            end
            Message.first_or_create :text => m
            twitter.update(
              "@#{status.user.screen_name} #{Message.random.text}",
              :in_reply_to_status_id => status.id)
            next
          end
          next unless status.text =~ PATTERN
          unless twitter.friendship?(status.user.screen_name, ENV['ACCOUNT'])
            twitter.unfollow status.user.id
            next
          end
          twitter.favorite_create status.id
          twitter.retweet status.id
          if rand < 0.5
            twitter.update(
              "@#{status.user.screen_name} #{Message.random.text}",
              :in_reply_to_status_id => status.id)
          end
        end
      end
    end

    PATTERN = Regexp.union([
      /☆|★/,
      /スター/,
      /消し(?:ゴム|ごむ)/,
      /eraser/,
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
      /鍋/,
    ])

  end
end
