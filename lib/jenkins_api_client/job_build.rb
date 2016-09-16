module JenkinsApi
    class Client

        #
        # This class represents a build with an assingned id. This includes
        # jobs already built or that are currently active.
        #
        class JobBuild
            VALID_PARAMS = ['id', 'name', 'params'].freeze
            attr_accessor :id, :name

            # Initializes a new [JobBuild]
            #
            # @param client [Client] the api client object
            # @param attr Hash with attributes containing at least name and id, the information not provided
            #       can be latter retrieved through the json api using the given client
            # 
            # @return [JobBuild] the build item object
            def initialize(client, attr = {})
                @client = client
                attr.each do |name, value|
                    name = name.to_s
                    if VALID_PARAMS.include?(name)
                        instance_variable_set("@#{name.to_s}", value)
                    end
                end
            end

            # @return Hash with build parameters
            #
            def params
                load_attributes
                @params
            end

            private

            # Queries the server for the missing information
            #
            def load_attributes
                if @params.nil?
                    json = @client.api_get_request("/job/#{@name}/#{@id}", "depth=2")
                    if json.member?('actions')
                        @params = json['actions'].find do |action|
                            if action.is_a?(Hash)
                                action.member?('parameters')
                            elsif action.is_a?(Array) 
                                action.first.is_a?(Hash) and action.first.member?('value')
                            end
                        end
                        if @params.nil?
                            @params = {}
                        else
                            @params = @params['parameters'] if @params.is_a?(Hash)
                            @params = @params.map do |param|
                                [param['name'], param['value']]
                            end
                            @params = Hash[@params]
                        end
                        
                    end
                end
            end
        end
    end
end
