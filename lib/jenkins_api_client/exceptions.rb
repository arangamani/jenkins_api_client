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

require 'logger'

module JenkinsApi
  # This module contains classes that define exceptions for various catories.
  #
  module Exceptions
    # This is the base class for Exceptions that is inherited from
    # RuntimeError.
    #
    class ApiException < RuntimeError
      def initialize(logger, message = "", log_level = Logger::ERROR)
        logger.add(log_level) { "#{self.class}: #{message}" }
        super(message)
      end
    end

    # This exception class handles cases where parameters are expected
    # but not provided.
    #
    class NothingSubmitted < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = "Nothing is submitted. #{message}"
        super(logger, msg)
      end
    end

    # This exception class handles cases where a job not able to be created
    # because it already exists.
    #
    class JobAlreadyExists < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        super(logger, message)
      end
    end
    # Support for backward compatibility
    JobAlreadyExistsWithName = JobAlreadyExists

    class ViewAlreadyExists < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        super(logger, message)
      end
    end

    class NodeAlreadyExists < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        super(logger, message)
      end
    end

    # This exception class handles cases where invalid credentials are provided
    # to connect to the Jenkins.
    #
    class Unauthorized < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = "Invalid credentials are provided. #{message}"
        super(logger, msg, Logger::FATAL)
      end
    end
    UnauthorizedException = Unauthorized

    # This exception class handles cases where invalid credentials are provided
    # to connect to the Jenkins.
    # While it is apparently used to indicate expiry of a Crumb, this is not
    # the only cause of a forbidden error... maybe the user just isn't allowed
    # to access the given url.  We should treat forbidden as a specific "you
    # are not welcome here"
    #
    class Forbidden < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = "Access denied. Please ensure that Jenkins is set up to allow" +
              " access to this operation. #{message}"
#              "The Crumb was expired or not sent to the server." +
#              " Perhaps the CSRF protection was not enabled on the server" +
#              " when the client was initialized. Please re-initialize the" +
#              " client. #{message}"
        super(logger, msg)
      end
    end
    # Support for backward compatibility
    ForbiddenException = Forbidden

    # This exception should be thrown specifically when the caller has had
    # a ForbiddenException and has been able to determine that a (valid)
    # crumb was used, and the attempt still failed.
    # This may require an interim attempt to re-acquire the crumb in order
    # to confirm it has not expired.
    # So:
    # def operation
    #   retried = false
    #   begin
    #     make_attempt
    #   rescue Forbidden => e
    #     refresh_crumbs(true)
    #     if @crumbs_enabled
    #       if !retried
    #         retried = true
    #         retry
    #       else
    #         raise ForbiddenWithCrumb.new(@logger, e.message)
    #       end
    #     else
    #       raise
    #     end
    #   end
    # end
    #
    # Note, the 'refresh_crumbs' method will update crumb enablement and the
    # stored crumb if called with 'true'
    #
    class ForbiddenWithCrumb < Forbidden
      def initialize(logger, message = '', log_level = Logger::ERROR)
        msg = "A crumb was used in attempt to access operation. #{message}"
        super(logger, msg)
      end
    end

    # This exception class handles cases where a requested page is not found on
    # the Jenkins API.
    #
    class NotFound < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = message.empty? ? "Requested component is not found on the" +
              " Jenkins CI server." : message
        super(logger, msg)
      end
    end
    # Support for backward compatibility
    NotFoundException = NotFound

    # This exception class handles cases where a requested page is not found on
    # the Jenkins API.
    #
    class CrumbNotFound < NotFound
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = "No crumb available on the server. #{message}"
        super(logger, msg)
      end
    end
    # Support for backward compatibility
    CrumbNotFoundException = CrumbNotFound

    class JobNotFound < NotFound
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = message.empty? ? "The specified job is not found" : message
        super(logger, msg)
      end
    end

    class ViewNotFound < NotFound
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = message.empty? ? "The specified view is not found" : message
        super(logger, msg)
      end
    end

    class NodeNotFound < NotFound
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = msg.empty? ? "The specified node is not found" : message
        super(logger, msg)
      end
    end

    # This exception class handles cases where the Jenkins API returns with a
    # 500 Internel Server Error.
    #
    class InternalServerError < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = "Internel Server Error. Perhaps the in-memory configuration of" +
              " Jenkins is different from the disk configuration." +
              " Please try to reload the configuration #{message}"
        super(logger, msg)
      end
    end
    # Support for backward compatibility
    InternalServerErrorException = InternalServerError

    # This exception class handles cases where the Jenkins is getting restarted
    # or reloaded where the response code returned is 503
    #
    class ServiceUnavailable < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = "Jenkins is being reloaded or restarted. Please wait till" +
              " Jenkins is completely back online. This can be" +
              " programatically achieved by System#wait_for_ready #{message}"
        super(logger, msg)
      end
    end
    # Support for backward compatibility
    ServiceUnavailableException = ServiceUnavailable

    # Exception occurred while running java CLI commands
    #
    class CLIError < ApiException
      def initialize(logger, message = "", log_level = Logger::ERROR)
        msg = "Execute CLI Error. #{message}"
        super(logger, msg)
      end
    end
    # Support for backward compatibility
    CLIException = CLIError
  end
end
