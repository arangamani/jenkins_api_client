#
# Specifying JenkinsApi::Client::Job class capabilities
# Author: Kannan Manickam <arangamani.kannan@gmail.com>
#

require File.expand_path('../spec_helper', __FILE__)
require 'yaml'

describe JenkinsApi::Client::BuildQueue do
  context "With properly initialized client" do
    before(:each) do
      @helper = JenkinsApiSpecHelper::Helper.new
      @creds_file = '~/.jenkins_api_client/spec.yml'
      @creds = YAML.load_file(File.expand_path(@creds_file, __FILE__))
      @job_name_prefix = 'awesome_rspec_test_job'
      @filter = "^#{@job_name_prefix}.*"
      @job_name = ''
      @valid_post_responses = [200, 201, 302]
      begin
        @client = JenkinsApi::Client.new(@creds)
      rescue Exception => e
        puts "WARNING: Credentials are not set properly."
        puts e.message
      end
      # Creating 10 jobs to run the spec tests on
      begin
        @client.node.create_dumb_slave(:name => 'none', :slave_host => '10.10.10.10', :private_key_file => '')
        10.times do |num|
          xml = @helper.create_job_with_params_xml
          job = "#{@job_name_prefix}_#{num}"
          @job_name = job if num == 0
          @client.job.create(job, xml).to_i.should == 200
        end
      rescue Exception => e
        puts "WARNING: Can't create jobs for preparing to spec tests"
        puts e.message
      end
    end

    describe "InstanceMethods" do

      describe "#initialize" do
        it "Initializes without any exception" do
          expect(
            lambda { job = JenkinsApi::Client::BuildQueue.new(@client) }
          ).not_to raise_error
        end
        it "Raises an error if a reference of client is not passed" do
          expect(
            lambda { job = JenkinsApi::Client::BuildQueue.new() }
          ).to raise_error
        end
      end

      describe "#list_tasks" do
          it "Gets all queued tasks as QueueItem objects" do
              10.times do |num|
                job = "#{@job_name_prefix}_#{num}"
                @job_name = job if num == 0
                @client.job.build(job, {"PARAM1" => num})
              end

              tasks = @client.queue.list_tasks
              expect(tasks).to be_a_kind_of(Array)
              tasks.each do |task|
                  expect(task).to be_a_kind_of(JenkinsApi::Client::QueueItem)
                  expect(task.params).to include("PARAM1")
                  expect(task.name).to eq("#{@job_name_prefix}_#{task.params['PARAM1']}")
              end
              tasks.size.should == 10
          end
      end

    end

    describe "QueueItem" do
      describe "#cancel" do
          it "Cancels an item in the queue" do
              5.times do |num|
                job = "#{@job_name_prefix}_3"
                @client.job.build(job, {"PARAM1" => num})
              end

              tasks = @client.queue.list_tasks
              tasks.size.should == 5

              tasks.each do |task|
                task.cancel if task.params['PARAM1'].to_i.even?
              end

              tasks = @client.queue.list_tasks
              tasks.map {|t| t.params['PARAM1']}.sort.should == ['1', '3']
          end
      end
    end

    after(:each) do
      job_names = @client.job.list(@filter)
      job_names.each { |job_name|
        @client.job.delete(job_name)
      }
      @client.node.delete_all!
    end

  end
end
