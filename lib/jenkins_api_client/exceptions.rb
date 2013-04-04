#
# Copyright (c) 2012-2013 Kannan Manickam <arangamani.kannan@gmail.com>
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

module JenkinsApi
  # This module contains classes that define exceptions for various catories.
  module Exceptions
    # This is the base class for Exceptions that is inherited from
    # RuntimeError.
    class ApiException < RuntimeError
      def initialize(message = "")
        super("Error: #{message}")
      end
    end

    # This exception class handles cases where invalid credentials are provided
    # to connect to the Jenkins
    class UnautherizedException < ApiException
      def initialize(message = "")
        super("Invalid credentials are provided. #{message}")
      end
    end

    # This exception class handles cases where a requested page is not found on
    # the Jenkins API
    class NotFoundException < ApiException
      def initialize(message = "")
        super("Requested component is not found on the Jenkins CI server." +
              " #{message}")
      end
    end

    # This exception class handles cases where the Jenkins API returns with a
    # 500 Internel Server Error
    class InternelServerErrorException < ApiException
      def initialize(message = "")
        super("Internel Server Error. Perhaps the in-memory configuration of" +
              " Jenkins is different from the disk configuration." +
              " Please try to reload the configuration #{message}"
             )
      end
    end

    # Exception occurred while running java CLI commands
    class CLIException < ApiException
      def initialize(message = "")
        super("Execute CLI Error. #{message}")
      end
    end
  end
end
