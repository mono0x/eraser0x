# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'json'
require 'twitter'
require 'userstream'

module Eraser
  class MessageManager
    def initialize(path)
      @path = path
      load
    end

    def load
      @messages = JSON.parse(open(@path, 'r:utf-8').read)['messages']
    end

    def add(m)
      unless @messages.include?(m)
        @messages.push m
        json = { 'messages' => @messages }.to_json
        open(@path, 'w') do |f|
          f << json
        end
      end
    end

    def get
      @messages[rand @messages.size]
    end
  end

  class Application
    def initialize(config)
      @config = config
      @messages = MessageManager.new('messages.json')
      reload
    end

    def reload
      instance_eval open(@config).read
    end

    def run
      twitter = ::Twitter::Client.new(
        :consumer_key       => @oauth[:consumer_key],
        :consumer_secret    => @oauth[:consumer_secret],
        :oauth_token        => @oauth[:oauth_token],
        :oauth_token_secret => @oauth[:oauth_token_secret])

      consumer = ::OAuth::Consumer.new(
        @oauth[:consumer_key],
        @oauth[:consumer_secret],
        :site => 'https://userstream.twitter.com/')

      access_token = ::OAuth::AccessToken.new(
        consumer,
        @oauth[:oauth_token],
        @oauth[:oauth_token_secret])

      userstream = ::Userstream.new(consumer, access_token)
      userstream.user do |status|
        STDERR.puts status.inspect
        case
        when status.event == 'follow'
          if status.source.screen_name != @account
            unless twitter.friendship?(@account, status.source.screen_name)
              twitter.follow status.source.id
            end
          end
        when status.event == 'favorite'
          next if status.source.screen_name == @account
          next unless twitter.friendship?(status.source.screen_name, @account)
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
          if status.direct_message.sender_screen_name == @author
            twitter.update status.direct_message.text
          end
        when status.text
          next if status.retweeted_status
          if status.text =~ /\A@#{@account}\s+(.+)\Z/m
            m = $1.gsub(/[@#]/, '_')
            unless twitter.friendship?(status.user.screen_name, @account)
              twitter.unfollow status.user.id
              next
            end
            @messages.add m
            twitter.update(
              "@#{status.user.screen_name} #{@messages.get}",
              :in_reply_to_status_id => status.id)
            next
          end
          next unless status.text =~ @pattern
          unless twitter.friendship?(status.user.screen_name, @account)
            twitter.unfollow status.user.id
            next
          end
          twitter.favorite_create status.id
          twitter.retweet status.id
          if rand < 0.05
            twitter.update(
              "@#{status.user.screen_name} #{@messages.get}",
              :in_reply_to_status_id => status.id)
          end
        end
      end
    end

    attr_reader :account
    attr_reader :author
    attr_reader :oauth
    attr_reader :pattern
  end
end

app = Eraser::Application.new('eraser.conf')

Signal.trap :HUP do
  STDERR.puts 'SIGHUP'
  app.reload
end

app.run

