require 'sinatra'
require 'line/bot'





API_KEY = ENV["OPENWEATHER_API_KEY"]

require "json"
require "open-uri"

url = open("https://api.openweathermap.org/data/2.5/weather?q=Tokyo,jp&APPID=#{API_KEY}")
response = JSON.parse( url.read , {symbolize_names: true} )

# 現在の天気
weather_id = response[:weather][0][:id].to_i

# weather_idを文字に変換

if weather_id == 800
  weather = "晴天"
elsif weather_id == 801
  weather = "晴れ"
elsif weather_id > 801
  weather = "曇り"
elsif weather_id >= 200 && weather_id < 300
  weather = "雷雨"
elsif weather_id >= 300 && weather_id < 400
  weather = "霧雨"
elsif weather_id == 500 || weather_id == 501
  weather = "雨"
elsif weather_id >= 502 && weather_id < 600
  weather = "大雨"
elsif weather_id >= 600 && weather_id < 700
  weather = "雪"
elsif weather_id >= 700 && weather_id < 800
  weather = "霧"
end

# 気温、湿度取得
temp_max = response[:main][:temp_max].to_i - 273
humidity = response[:main][:humidity].to_i


now_weather = "現在の東京の天気は#{weather}, 気温は#{temp_max}度の湿度は#{humidity}%です。お気をつけて。"





def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  omikuji = ["大吉!!", "中吉", "小吉", "凶..", "大凶..."].sample

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        case event.message['text']
        when 'テスト'
          message = {type: 'text',text: 'テスト成功です'}
        when 'おみくじ'
          message = {type: 'text', text: omikuji}
        when '天気'
          message = {type: 'text', text: now_weather}
        else
          message = {type: 'text',text: event.message['text']}
        end
      client.reply_message(event['replyToken'], message)
      end
    end
  }
  "OK"
end