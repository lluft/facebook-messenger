require 'httparty'

module Facebook
  module Messenger
    # This module handles subscribing and unsubscribing Applications to Pages.
    module Subscriptions
      include HTTParty

      base_uri 'https://graph.facebook.com/v2.6/me'

      def self.subscribe(access_token)
        response = post '/subscribed_apps', query: {
          access_token: access_token
        }

        raise_errors(response)

        true
      end

      def self.unsubscribe(access_token)
        response = delete '/subscribed_apps', query: {
          access_token: access_token
        }

        raise_errors(response)

        true
      end

      def self.raise_errors(response)
        raise Error, response['error']['message'] if response.key? 'error'
      end

      class Error < Facebook::Messenger::Error; end
    end
  end
end
