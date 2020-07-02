# frozen_string_literal: true

require 'bridge/api/wrapper/version'

# frozen_string_literal: true

require_relative './http_status_codes'

module Bridge
  module API
    class Wrapper
      include HttpStatusCodes

      attr_reader :auth_token, :domain

      def initialize(auth_token, domain)
        @auth_token = auth_token
        @domain = domain
      end

      def users(id = nil)
        path = if id
                 "/api/author/users/#{id}"
               else
                 '/api/author/users?limit=1000'
        end

        request(
          http_method: :get,
          endpoint: path
        )
      end

      def courses(id = nil)
        path = if id
                 "/api/author/course_templates/#{id}"
               else
                 '/api/author/course_templates?limit=1000'
        end

        request(
          http_method: :get,
          endpoint: path
        )
      end

      def live_trainings(id = nil)
        path = if id
                 "/api/author/live_courses/#{id}"
               else
                 '/api/author/live_courses?limit=1000'
        end

        request(
          http_method: :get,
          endpoint: path
        )
      end

      def programs(id = nil)
        path = if id
                 "/api/author/programs/#{id}"
               else
                 '/api/author/programs?limit=1000'
        end

        request(
          http_method: :get,
          endpoint: path
        )
      end

      def checkpoints(id = nil)
        path = if id
                 "/api/author/tasks/#{id}"
               else
                 '/api/author/tasks?limit=1000'
        end

        request(
          http_method: :get,
          endpoint: path
        )
      end

      private

      def client
        @_client ||= Faraday.new("https://#{domain}.bridgeapp.com") do |client|
          client.request :url_encoded
          client.adapter Faraday.default_adapter
          client.headers['Authorization'] = auth_token
        end
      end

      def request(http_method:, endpoint:, params: {})
        items = []
        response = client.public_send(http_method, endpoint, params)
        parsed_response = Oj.load(response.body)

        if response_successful?(response)
          puts HTTP_OK_CODE
          if parsed_response['meta']['next']
            while parsed_response['meta']['next']
              puts parsed_response['meta']['next']
              data = parsed_response['users'] ||
                     parsed_response['programs'] ||
                     parsed_response['live_trainings'] ||
                     parsed_response['tasks']
              data.each { |item| items << item }
              # response = HTTParty.get(data['meta']['next'], headers: headers)
              response = request(
                http_method: :get,
                endpoint: parsed_response['meta']['next']
              )
            end
          else
            items = parsed_response
          end

          items
        else
          raise error_class(response), "code #{response.status}, response: #{response.body}"
        end
    end

      def error_class(response)
        case response.status
        when HTTP_BAD_REQUEST_CODE
          error = { error: :HTTP_BAD_REQUEST_CODE }
          p error
        when HTTP_UNAUTHORIZED_CODE
          error = { error: :HTTP_UNAUTHORIZED_CODE }
          p error
        when HTTP_FORBIDDEN_CODE
          error = { error: :HTTP_FORBIDDEN_CODE }
          p error
        when HTTP_NOT_FOUND_CODE
          error = { error: :HTTP_NOT_FOUND_CODE }
          p error
        when HTTP_UNPROCESSABLE_ENTITY_CODE
          error = { error: :HTTP_UNPROCESSABLE_ENTITY_CODE }
          p error
        else
          error = { error: :UNKNOWN_ERROR }
          p error
        end
      end

      def response_successful?(response)
        response.status == HTTP_OK_CODE
      end
    end
  end
end

# bridge_client = BridgeAPIWrapper::V1::Client.new(token, domain)
