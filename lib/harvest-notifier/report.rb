# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

module HarvestNotifier
  class Report
    attr_reader :harvest_client, :emails_whitelist, :missing_hours_threshold

    delegate :users_list, :time_report_list, to: :harvest_client, prefix: :harvest

    def initialize(harvest_client)
      @harvest_client = harvest_client

      @emails_whitelist = ENV.fetch("EMAILS_WHITELIST", "").split(",").map(&:strip)
      @missing_hours_threshold = ENV.fetch("MISSING_HOURS_THRESHOLD", 1.0).to_f
    end

    def daily
      users = prepare_users(harvest_users_list)
      reports = harvest_time_report_list(Date.yesterday)

      filter_users_with_reports(users, reports) do |user|
        whitelisted_email?(user["email"]) || time_reported?(user)
      end
    end

    def weekly
      users = prepare_users(harvest_users_list)
      reports = harvest_time_report_list(Date.today.last_week, Date.today.last_week + 4)

      filter_users_with_reports(users, reports) do |user|
        whitelisted_email?(user["email"]) || full_time_reported?(user)
      end
    end

    private

    def filter_users_with_reports(users, reports)
      prepare_users_with_reports(users, reports)
        .reject { |_id, user| yield(user) }
        .values
    end

    def prepare_users(users)
      users["users"]
        .group_by { |u| u["id"] }
        .transform_values { |u| prepared_user(u.first) }
    end

    def prepared_user(user)
      hours = user["weekly_capacity"] / 3600

      {
        "email" => user["email"],
        "weekly_capacity" => hours,
        "missing_hours" => hours,
        "total_hours" => 0
      }
    end

    def prepare_users_with_reports(users, reports)
      reports["results"].each.with_object(users) do |report, result|
        id = report["user_id"]

        result[id]["missing_hours"] -= report["total_hours"]
        result[id]["total_hours"] += report["total_hours"]
      end
    end

    def whitelisted_email?(email)
      emails_whitelist.include?(email)
    end

    def time_reported?(user)
      user["total_hours"].positive?
    end

    def full_time_reported?(user)
      time_reported?(user) && missing_hours_insignificant?(user)
    end

    def missing_hours_insignificant?(user)
      user["missing_hours"] <= missing_hours_threshold
    end
  end
end
