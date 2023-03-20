require 'uri'
require 'addressable/uri'

module JenkinsApi
  module UriHelper
    # Encode a string for using in the query part of an URL
    #
    def form_encode(string)
      URI.encode_www_form_component string.encode(Encoding::UTF_8)
    end

    # Encode a string for use in the hiearchical part of an URL
    #
    def path_encode(path)
      Addressable::URI.escape(path.encode(Encoding::UTF_8))
    end
  end
end
