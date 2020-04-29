# frozen_string_literal: true

require "httparty"

module HarvestNotifier
  class Slack
    include HTTParty

    base_uri "https://slack.com/api"

    def initialize(token)
      @token = token
    end

    def post_message(body)
      self.class.post(
        "/chat.postMessage",
        headers: {
          "Content-type" => "application/json",
          "Authorization" => "Bearer #{ENV['SLACK_TOKEN']}"
        },
        body: body
      )
    end

    def users_list
      data = []
      receive_users_list.map do |user|
        next if user["deleted"] == true || user["is_bot"] == true

        data << { id: user["id"], email: user["profile"]["email"] }
      end

      data
    end

    private

    def receive_users_list
      self.class.get(
        "/users.list",
        headers: {
          "Authorization" => "Bearer #{@token}"
        }
      )["members"]
    end
  end
end
