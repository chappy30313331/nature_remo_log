require 'dotenv/load'
require 'slack/incoming/webhooks'

class SlackClient
  def initialize
    @client = Slack::Incoming::Webhooks.new ENV["SLACK_WEBHOOK_URL"]
  end

  def post(message)
    @client.post message
  end
end
