require 'uri'
require 'json'
require 'http'
require 'erb'
require 'active_record'
require 'dotenv/load'
require './slack_client'

config = YAML::load(ERB.new(IO.read('./database.yml')).result)
ActiveRecord::Base.establish_connection(config.fetch(ENV.fetch('RUBY_ENV') { 'production' }))
Time.zone_default = Time.find_zone! 'Tokyo'
ActiveRecord::Base.default_timezone = :local

class RemoLog < ActiveRecord::Base; end

def fetch_remo
  response = HTTP.headers('Accept' => 'application/json', 'Authorization' => "Bearer #{ENV['REMO_TOKEN']}")
                 .get(URI.parse('https://api.nature.global/1/devices'))
  JSON.parse(response)
end

begin
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
  )
rescue => e
  SlackClient.new.post <<~"EOS"
    ```
    #{e.message}
    #{e.backtrace.join("\n")}
    ```
  EOS
end
