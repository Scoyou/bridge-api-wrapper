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

      def fetch_users(id = nil)
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

      def create_users(params)
        # params must be a JSON object
        path = '/api/admin/users'
        request(
          http_method: :post,
          endpoint: path,
          params: params
        )
      end

      def modify_or_delete_users(id, action, params = nil)
        # params must be a JSON object
        case action
        when 'update'
          path = "/api/author/users/#{id}"
          request(
            http_method: :patch,
            endpoint: path,
            params: params
          )
        when 'delete'
          path = "/api/admin/users/#{id}"
          request(
            http_method: :delete,
            endpoint: path
          )
        else
          error = {error: :INVALID_ACTION}
          p error
        end
      end

      def fetch_courses(id = nil)
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

      def fetch_live_trainings(id = nil)
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

      def fetch_programs(id = nil)
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

      def fetch_checkpoints(id = nil)
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

      def fetch_completed_learners_report(params = nil)
        path = "/api/admin/reports/CompletedLearnersReport?#{params}"
        request(
          http_method: :get,
          endpoint: path
        )
      end

      def fetch_enrollments(type, id)
        case type
        when 'course_template'
          path = "/api/author/course_templates/#{id}/enrollments?limit=1000"
        when 'live_course'
          path = "/api/live_courses/#{id}/learners?limit=1000"
        when 'program'
          path = "/api/author/programs/#{id}/learners?limit=1000"
        when 'task'
          path = "/api/author/tasks/#{id}/learners?limit=1000"
        end
        request(
          http_method: :get,
          endpoint: path
        )
      end

      def create_enrollments(type, content_id, users)
        case type
        when 'course_template'
          path = "/api/author/course_templates/#{content_id}/enrollments"
        when 'program'
          path = "/api/author/programs/#{content_id}/learners"
        when 'live_course'
          path = "/api/author/live_courses/#{content_id}/learners"
        when 'task'
          path = "/api/author/tasks/#{content_id}/learners"
        else
          error = {error: :INVALID_CONTENT_TYPE}
          p error
        end
        request(
          http_method: :post,
          endpoint: path,
          params: users
        )
      end

      def modify_or_delete_enrollments(id, action, params = nil)
        case action
        when 'update'
          path = "/api/author/enrollments/#{id}"
          request(
            http_method: :patch,
            endpoint: path,
            params: params
          )
        when 'delete'
          path = "/api/author/enrollments/#{id}"
          request(
            http_method: :delete,
            endpoint: path
          )
        else
          error = {error: :INVALID_ACTION}
          p error
        end
      end

      def re_enroll_learners(course_id, user_id)
        path = "/api/author/course_templates/#{course_id}/learners/#{user_id}/re_enroll"
        response = request(
          http_method: :post,
          endpoint: path
        )
        p response
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

              data = parsed_response['users'] if parsed_response['users']
              data = parsed_response['programs'] if parsed_response['programs']
              data = parsed_response['live_trainings'] if parsed_response['live_trainings']
              data = parsed_response['tasks'] if parsed_response['tasks']
              data = parsed_response['reports'][0]['data'] if parsed_response['reports']
              data = parsed_response['linked']['learners'] if parsed_response['linked']['learners']
              data = parsed_response['linked']['enrollments'] if parsed_response['linked']['enrollments']

              data.each { |item| items << item }
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
