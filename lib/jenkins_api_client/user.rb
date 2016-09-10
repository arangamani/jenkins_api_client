#
# Copyright (c) 2012-2013 Douglas Henderson <dougforpres@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'timeout'
require 'jenkins_api_client/urihelper'

module JenkinsApi
  class Client
    # This class is used to communicate with Jenkins and performing some user
    # level operations - currently limited to fetching user info, but can
    # be extended to support updating user fields
    #
    # @since 0.14.0
    #
    class User
      include JenkinsApi::UriHelper

      # Initializes a new User object.
      #
      # @param client [Client] the client object
      #
      # @return [User] the user object
      #
      def initialize(client)
        @client = client
        @logger = @client.logger
        @timeout = @client.timeout
      end

      # Returns a string representation of User class.
      #
      def to_s
        "#<JenkinsApi::Client::User>"
      end

      # Get a list of users
      # Response will include same as is available from
      # http://jenkins/user/#{username}
      # userid, display name, and email-address
      #
      # @return [Hash] of [Hash], keyed by Jenkins user id
      #   * +fullName+ The jenkins user idoutput+ Console output of the job
      #   * +properties+ Size of the text. This ca
      #
      def list
        @logger.info "Obtaining the list of users from jenkins"
        # First we need to get the list of users.
        # This is the same as "System.list_users", but since I didn't want to
        # depend on that class I reproduced the request here.
        userlist = @client.api_get_request("/asynchPeople")
        users = {}

        userlist['users'].each { |user|
          # Jenkins seems ok to fetch by full-name, as long as perfect match
          # since the name *came* from Jenkins this seems reasonably safe
          user = get(user['user']['fullName'])
          users[user['id']] = user if user
        } unless userlist.nil?

        return users
      end

      # Get a single user
      #
      # @param user_id [String] User ID or Full Name
      #
      # @return [Hash]
      #   * +id+ Jenkins user id
      #   * +fullName+ Full name of user (or user id if not set)
      #   * other fields populated by Jenkins - this may vary based on version/plugins
      #
      # @example Example JSON for user info
      #   {
      #     "absoluteUrl" : "https://myjenkins.example.com/jenkins/user/fred",
      #     "description" : "",
      #     "fullName" : "Fred Flintstone",
      #     "id" : "fred",
      #     "property" : [
      #       {
      #       },
      #       {
      #       },
      #       {
      #         "address" : "fred@slaterockandgravel.com"
      #       },
      #       {
      #       },
      #       {
      #       },
      #       {
      #         "insensitiveSearch" : false
      #       }
      #     ]
      #   }
      #
      def get(user_id)
        @client.api_get_request("/user/#{path_encode user_id}")
      end

      def get_api_token(user_id)
        response = @client.api_get_request("/user/#{path_encode user_id}/configure", nil, '')
        html = Nokogiri::HTML(response)
        attr = html.xpath('//input[@id="apiToken"]/@value').first
        if attr.nil?
          raise Exceptions::ApiException.new(@logger, "Failed to get api token")
        end
        attr.value
      end

    end
  end
end
