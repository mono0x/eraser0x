# -*- coding: utf-8 -*-

module Eraser
  class Application
    def run
      Twitter.configure do |config|
        config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
        config.oauth_token        = ENV['TWITTER_OAUTH_TOKEN']
        config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
      end

      UserStream.configure do |config|
        config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
        config.oauth_token        = ENV['TWITTER_OAUTH_TOKEN']
        config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
      end

      random = Random.new

      UserStream.client.user do |status|
        STDERR.puts status.inspect
        case
        when status.event == 'follow'
          if status.source.screen_name != ENV['ACCOUNT']
            unless Twitter.friendship?(ENV['ACCOUNT'], status.source.screen_name)
              Twitter.follow status.source.id
            end
          end
        when status.event == 'favorite'
          next if status.source.screen_name == ENV['ACCOUNT']
          next unless Twitter.friendship?(status.source.screen_name, ENV['ACCOUNT'])
          timeline = Twitter.user_timeline(status.source.screen_name).select {|s|
            !s.retweeted_status && !s.in_reply_to_status_id && !s.favorited
          }
          next if timeline.empty?
          target = timeline.sample
          begin
            Twitter.favorite_create target.id
            Twitter.retweet target.id
          rescue
          end
        when status.direct_message
          if status.direct_message.sender_screen_name == ENV['AUTHOR']
            Twitter.update status.direct_message.text
          end
        when status.text
          next if status.retweeted_status
          if status.text =~ /\A@#{ENV['ACCOUNT']}\s+(.+)\Z/m
            m = $1.gsub(/[@#]/, '_')
            unless Twitter.friendship?(status.user.screen_name, ENV['ACCOUNT'])
              Twitter.unfollow status.user.id
              next
            end
            Message.first_or_create :text => m
            Twitter.update(
              "@#{status.user.screen_name} #{Message.random(random).text}",
              :in_reply_to_status_id => status.id)
            next
          end
          next unless status.text =~ PATTERN
          unless Twitter.friendship?(status.user.screen_name, ENV['ACCOUNT'])
            Twitter.unfollow status.user.id
            next
          end
          Twitter.favorite_create status.id
          Twitter.retweet status.id
          if rand < 0.5
            Twitter.update(
              "@#{status.user.screen_name} #{Message.random(random).text}",
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
      %r{帰.?っ.?た},
    ])

  end
end
