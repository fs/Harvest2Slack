# frozen_string_literal: true

require "harvest-notifier/templates/base"

module HarvestNotifier
  module Templates
    class DailyReport < Base
      REMINDER_TEXT = "*Guys, don't forget to report the working hours in Harvest every day.*"
      LIST_OF_USERS = "Here is a list of people who didn't report the working hours for *%<current_date>s*:"
      REPORT_NOTICE = "_Please, report time and react with :heavy_check_mark: for this message._"

      def generate # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        Jbuilder.encode do |json| # rubocop:disable Metrics/BlockLength
          json.channel channel
          json.blocks do # rubocop:disable Metrics/BlockLength
            # Reminder text
            json.child! do
              json.type "section"
              json.text do
                json.type "mrkdwn"
                json.text REMINDER_TEXT
              end
            end
            # Pretext list of users
            json.child! do
              json.type "section"
              json.text do
                json.type "mrkdwn"
                json.text format(LIST_OF_USERS, current_date: slack_formatting)
              end
            end
            # List of users
            json.child! do
              json.type "section"
              json.text do
                json.type "mrkdwn"
                json.text users_list.join(" \n • ").prepend("• ")
              end
            end
            # Report notice
            json.child! do
              json.type "section"
              json.text do
                json.type "mrkdwn"
                json.text REPORT_NOTICE
              end
            end
            # Report Time button
            json.child! do
              json.type "actions"
              json.elements do
                json.child! do
                  json.type "button"
                  json.url url
                  json.style "primary"
                  json.text do
                    json.type "plain_text"
                    json.text "Report Time"
                  end
                end
              end
            end
          end
        end
      end

      private

      def slack_formatting
        "<!date^#{assigns[:date].to_time.to_i}^{date_short}th|yesterday>"
      end

      def users_list
        assigns[:users].map do |u|
          u[:slack_id] ? "<@#{u[:slack_id]}>" : u[:email]
        end
      end
    end
  end
end
