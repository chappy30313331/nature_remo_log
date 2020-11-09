require 'net/http'
require 'uri'
require 'openssl'
require 'json'
require 'active_record'
require 'dotenv/load'

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

ENDPOINT = 'https://api.nature.global/1/devices'.freeze

def fetch
  uri = URI.parse(ENDPOINT)
  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'application/json'
  request['Authorization'] = "Bearer #{ENV['REMO_TOKEN']}"
  req_options = {
    use_ssl: uri.scheme == "https",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }

  JSON.parse(response.body)
end

response = fetch
newest_events = response.first['newest_events']

RemoLog.create(
  measured_at: Time.now,
  humidity: newest_events.dig('hu', 'val'),
  humidity_created_at: newest_events.dig('hu', 'created_at'),
  illumination: newest_events.dig('il', 'val'),
  illumination_created_at: newest_events.dig('il', 'created_at'),
  motion: newest_events.dig('mo', 'val'),
  motion_created_at: newest_events.dig('mo', 'created_at'),
  temperature: newest_events.dig('te', 'val'),
  temperature_created_at: newest_events.dig('te', 'created_at')
)
