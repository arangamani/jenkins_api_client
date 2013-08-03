require File.expand_path('../spec_helper', __FILE__)

describe JenkinsApi::Client::User do
  context "With properly initialized Client" do
    FRED_TXT = <<__FRED
{
  "absoluteUrl" : "https://myjenkins.example.com/jenkins/user/fred",
  "description" : "",
  "fullName" : "Fred Flintstone",
  "id" : "fred",
  "property" : [
    {
    },
    {
    },
    {
      "address" : "fred@slaterockandgravel.com"
    },
    {
    },
    {
    },
    {
      "insensitiveSearch" : false
    }
  ]
}
__FRED

    WILMA_TXT = <<__WILMA
{
  "absoluteUrl" : "https://myjenkins.example.com/jenkins/user/wilma",
  "description" : "",
  "fullName" : "wilma",
  "id" : "wilma",
  "property" : [
    {
    },
    {
    },
    {
    },
    {
    },
    {
    },
    {
    }
  ]
}
__WILMA

    FRED_JSON = JSON.parse(FRED_TXT)
    WILMA_JSON = JSON.parse(WILMA_TXT)
    PEOPLE_JSON = JSON.parse(<<__PEEPS
{
  "users" : [
    {
      "lastChange" : 1375293464494,
      "project" : {
        "name" : "a project",
        "url" : "a url to a project"
      },
      "user" : {
        "absoluteUrl" : "a url to a user",
        "fullName" : "Fred Flintstone"
      }
    }
  ]
}
__PEEPS
)

    USERLIST_JSON = JSON.parse(<<__USERLIST
{
  "fred": #{FRED_TXT}
}
__USERLIST
)
 
    before do
      mock_logger = Logger.new "/dev/null"
      mock_timeout = 300
      @client = mock
      @client.should_receive(:logger).and_return(mock_logger)
      @client.should_receive(:timeout).and_return(mock_timeout)
      @client.stub(:api_get_request).with('/asynchPeople').and_return(PEOPLE_JSON)
      @client.stub(:api_get_request).with('/user/Fred Flintstone').and_return(FRED_JSON)
      @client.stub(:api_get_request).with('/user/fred').and_return(FRED_JSON)
      @client.stub(:api_get_request).with('/user/wilma').and_return(WILMA_JSON)
      @user = JenkinsApi::Client::User.new(@client)
    end

    describe "InstanceMethods" do
      describe "#initialize" do
        it "initializes by receiving an instance of client object" do
          mock_logger = Logger.new "/dev/null"
          mock_timeout = 300
          @client.should_receive(:logger).and_return(mock_logger)
          @client.should_receive(:timeout).and_return(mock_timeout)
          expect(
            lambda{ JenkinsApi::Client::User.new(@client) }
          ).not_to raise_error
        end
      end

      describe "#list_users" do
        it "sends a request to list the users" do
          @user.list.should eq(USERLIST_JSON)
        end
      end

      describe "#get_user" do
        it "returns dummy user if user cannot be found" do
          # This is artifact of Jenkins - It'll create a user to match the name you give it - even on a fetch
          @user.get("wilma").should eq(WILMA_JSON)
        end

        it "returns valid user if user can be found" do
          @user.get("fred").should eq(FRED_JSON)
        end
      end

    end
  end
end
