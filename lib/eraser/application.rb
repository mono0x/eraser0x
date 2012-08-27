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

      horoscopes_messages = {
        capricorn:   'やぎ座',
        aquarius:    'みずがめ座',
        pisces:      'うお座',
        aries:       'おひつじ座',
        taurus:      'おうし座',
        gemini:      'ふたご座',
        cancer:      'かに座',
        leo:         'しし座',
        virgo:       'おとめ座',
        libra:       'てんびん座',
        scorpius:    'さそり座',
        sagittarius: 'いて座',
      }

      paper_fortune_messages = [
        '大吉',
        '中吉',
        '小吉',
        '吉',
        '半吉',
        '末吉',
        '末小吉',
        '凶',
        '小凶',
        '半凶',
        '末凶',
        '大凶',
      ]

      paper_fortune_weights = [ 3, 5, 7, 10, 10, 15, 15, 10, 10, 7, 5, 3 ]

      random = Random.new

      UserStream.client.user do |status|
        STDERR.puts status.inspect
        case
        when status.event == 'follow'
          next if status.source.screen_name == ENV['ACCOUNT']
          next if Twitter.friendship?(ENV['ACCOUNT'], status.source.screen_name)
          next unless Twitter.friendship?(ENV['AUTHOR'], status.source.screen_name)
          Twitter.follow status.source.id
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
            case m
            when /おみくじ/
              p = paper_fortune_messages[PaperFortune.paper_fortune(paper_fortune_weights, Date.today, status.user.screen_name)]
              Twitter.update(
                "@#{status.user.screen_name} #{p}",
                :in_reply_to_status_id => status.id)
            when %r!星座占い.*?(?:(\d+)[月/](\d+)|(#{Regexp.union(horoscopes_messages.values)}))!
              a = horoscopes_messages.key($3) || Horoscopes.astrology(Date.new(2000, $1.to_i, $2.to_i))
              Twitter.update(
                "@#{status.user.screen_name} #{horoscopes_messages[a]}: #{Horoscopes.horoscopes.find_index {|h| h == a } + 1}位",
                :in_reply_to_status_id => status.id)
            else
              Message.first_or_create :text => m
              Twitter.update(
                "@#{status.user.screen_name} #{Message.random(random).text}",
                :in_reply_to_status_id => status.id)
              next
            end
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
