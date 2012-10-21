module JenkinsApi
  class Client
    class Feature

    def initialize(job)
      @job = job
    end

    def chain_jobs(job_names)
      puts job_names
    end

    end
  end
end
