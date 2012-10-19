module JenkinsApi
  module Exceptions
    class ApiException < RuntimeError
      def initialize(message = "")
        super("Error: #{message}")
      end
    end

    class UnautherizedException < ApiException
      def initialize(message = "")
        super("Invalid credentials are provided. #{message}")
      end
    end

    class NotFoundException < ApiException
      def initialize(message = "")
        super("Requested page not found on the Jenkins CI server. #{message}")
      end
    end

    class InternelServerErrorException < ApiException
      def initialize(message = "")
        super("Internel Server Error. #{message}")
      end
    end
  end
end
