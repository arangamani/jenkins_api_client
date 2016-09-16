module JenkinsApi
    class Client

        #
        # This class represents an item in the building queue and allows interaction
        # with an identified queue item.
        #
        class QueueItem
            VALID_PARAMS = ['id', 'params'].freeze
            attr_accessor *VALID_PARAMS.each {|attr| attr.to_sym}
            attr_accessor :name

            # Initializes a new QueueItem
            #
            # @param client [Cliente] the api client object
            # @param json the json object with all the information of the queue item (as returned by api call "/queue")
            #
            # @return [QueueItem] the queue item object
            #
            def initialize(client, json)
                @client = client
                json.each do |key, value|
                    if VALID_PARAMS.include?(key)
                        instance_variable_set("@#{key}", value)
                    end
                end if json.is_a? Hash
                @name = json['task']['name']

                # parseamos los parametros
                @params = @params.split("\n").map do |p|
                    p.split('=')
                end.select do |p|
                    not p.empty?
                end
                @params = Hash[@params]
            end

            # String representation of the queue item object
            #
            def to_s
                self.name
            end

            # Removes the item from the building queue
            #
            def cancel
                @client.api_post_request("/queue/cancelItem?id=#{self.id}")
            end
        end
    end
end
