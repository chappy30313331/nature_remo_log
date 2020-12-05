require 'uri'
require 'json'
require 'http'
require 'active_record'
require 'dotenv/load'
require './slack_client'

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: ENV['DB_DATABASE'],
  host: ENV['DB_HOST'],
  username: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD']
)
Time.zone_default = Time.find_zone! 'Tokyo'
ActiveRecord::Base.default_timezone = :local

class RemoLog < ActiveRecord::Base; end

def fetch_remo
  response = HTTP.headers('Accept' => 'application/json', 'Authorization' => "Bearer #{ENV['REMO_TOKEN']}")
                 .get(URI.parse('https://api.nature.global/1/devices'))
  JSON.parse(response)
end

def fetch_co2
  response = HTTP.get(URI::HTTP.build(host: ENV['CO2_HOST']))
  JSON.parse(response)
end

begin
  co2 = fetch_co2
  remo = fetch_remo.first['newest_events']
  RemoLog.create(
    measured_at: Time.now,
    humidity: remo.dig('hu', 'val'),
    humidity_created_at: remo.dig('hu', 'created_at'),
    illumination: remo.dig('il', 'val'),
    illumination_created_at: remo.dig('il', 'created_at'),
    motion: remo.dig('mo', 'val'),
    motion_created_at: remo.dig('mo', 'created_at'),
    temperature: remo.dig('te', 'val'),
    temperature_created_at: remo.dig('te', 'created_at'),
    co2: co2['value']
  )
rescue => e
  SlackClient.new.post <<~"EOS"
    ```
    #{e.message}
    #{e.backtrace.join("\n")}
    ```
  EOS
end
