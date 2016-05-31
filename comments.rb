# coding: utf-8
require 'open-uri'
require "net/http"
require "uri"
require "json"

require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load

cache = Dalli::Client.new
cached_comment_id = cache.get('max_comment_id') || 0

doc = Nokogiri::HTML(open(ENV['KICKSTARTER_URL']+"/comments"))

comments = doc.css('.comment')
max_comment_id = 0

comments.each do |comment|
  comment_id = comment.attr('id').gsub(/comment-/,'').to_i

  if comment_id > cached_comment_id

    author = comment.css("a")[1].text
    text = comment.css("p").map { |p| p.text }.join("\n")
    link = comment.css("a")[2].attr("href")

    payload= {
      text: "<https://www.kickstarter.com#{link}|#{author} commented>\n#{text}",
      icon_url: "https://www.kickstarter.com/download/kickstarter-logo-k-color.png",
      channel: ENV['SLACK_COMMENTS_ROOM'],
      username: 'Kickstarter',
    }
    Net::HTTP.post_form(URI.parse(ENV['SLACK_URL']), {payload: JSON.dump(payload)})

  end
  if comment_id > max_comment_id
    max_comment_id = comment_id
  end
end

cache.set('max_comment_id', max_comment_id)
