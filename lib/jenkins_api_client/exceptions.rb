module JenkinsApi
  module Exceptions
    class ApiException < RuntimeError

      def initialize(message="")
        super("Error: #{message}")
      end

    end
  end
end
