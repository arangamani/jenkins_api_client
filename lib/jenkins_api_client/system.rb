#
# Copyright (c) 2012 Kannan Manickam <arangamani.kannan@gmail.com>
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

module JenkinsApi
  class Client
    class System

      # Initializes a new System object.
      #
      # @param [Object] client a reference to Client
      #
      def initialize(client)
        @client = client
      end

      # Returns a string representation of System class.
      #
      def to_s
        "#<JenkinsApi::Client::System>"
      end

      # Sends a quiet down request to the server.
      #
      def quiet_down
        @client.api_post_request("/quietDown")
      end

      # Cancels the quiet doen request sent to the server.
      #
      def cancel_quiet_down
        @client.api_post_request("/cancelQuietDown")
      end

      # Restarts the Jenkins server
      #
      # @param [Bool] force whether to force restart or wait till all jobs are completed.
      #
      def restart(force = false)
        if force
          @client.api_post_request("/restart")
        else
          @client.api_post_request("/safeRestart")
        end
      end

      # This method waits till the server becomes ready after a start or restart.
      #
      def wait_for_ready
        Timeout::timeout(120) do
          while true do
            response = @client.get_root
            puts "[INFO] Waiting for jenkins to restart..." if @client.debug
            if (response.body =~ /Please wait while Jenkins is restarting/ || response.body =~ /Please wait while Jenkins is getting ready to work/)
              sleep 30
              redo
            else
               return true
            end
          end
        end
        false
      end

      def list_permissions(user_name)
        xml = @client.get_config("/computer/(master)")
        n_xml = Nokogiri::XML(xml)
        #puts xml
        users = n_xml.xpath("//authorizationStrategy").first
        user_details = []
        users.children.each do |detail|
          # puts user_details
          user_details << detail.content if detail.content =~ /hudson/ && detail.content.split(':')[1] == user_name
        end
        permissions = {}
        permissions[:computer] = []
        permissions[:hudson] = []
        permissions[:item] = []
        permissions[:view] = []
        permissions[:run] = []
        permissions[:scm] = []
        user_details.each do |detail|
          if detail =~ /Computer/
            permissions[:computer] << detail.split('.')[3].split(':')[0].downcase
          elsif detail =~ /Hudson/
            permissions[:hudson] << detail.split('.')[3].split(':')[0].downcase
          elsif detail =~ /Item/
            permissions[:item] << detail.split('.')[3].split(':')[0].downcase
          elsif detail =~ /View/
            permissions[:view] << detail.split('.')[3].split(':')[0].downcase
          elsif detail =~ /Run/
            permissions[:run] << detail.split('.')[3].split(':')[0].downcase
          elsif detail =~ /SCM/
            permissions[:scm] << detail.split('.')[3].split(':')[0].downcase
          end
       end
       permissions
      end

      def disable_signup(option)
        xml = @client.get_config("/computer/(master)")
        n_xml = Nokogiri::XML(xml)
        disable_signup = n_xml.xpath("//disableSignup").first
        if disable_signup.content != option
          disable_signup.content = disable_signup.content == true ? false : true
          xml_modified = n_xml.to_xml
          puts xml_modified
          @client.post_config("/computer/(master)/config.xml", xml_modified)
        end
      end

      def enable_captcha(option)
        xml = @client.get_config("/computer/(master)")
        n_xml = Nokogiri::XML(xml)
        enable_captcha = n_xml.xpath("//enableCaptcha").first
        if enable_captcha.content != option
          enable_captcha.content = enable_captcha.content == true ? false : true
          xml_modified = n_xml.to_xml
          puts xml_modified
          @client.post_config("/computer/(master)/config.xml", xml_modified)
        end
      end

    end
  end
end
