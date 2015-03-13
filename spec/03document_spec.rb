#!ruby

require 'noms/command/document'

describe "NOMS::Command::Document" do
    before(:all) do
        FileUtils.mkdir_p('test')

        File.open('test/foo.txt', 'w') do |fh|
            fh << <<-EOF.gsub(/^\s{12}/,'')
            Test output for local file foo.txt
            EOF
        end

        File.open("test/start-app-#{Process.pid}.sh", 'w') do |fh|
            fh << <<-EOF.gsub(/^\s{12}/,'')
            #!/bin/bash
            nohup #{RbConfig.ruby} #{Dir.pwd}/test/test-app-#{Process.pid}.rb >#{Dir.pwd}/test/test-app-#{Process.pid}.out </dev/null 2>&1 &
            EOF
        end
        FileUtils.chmod(0755, "test/start-app-#{Process.pid}.sh")

        File.open("test/test-app-#{Process.pid}.rb", 'w') do |fh|
            fh << <<-EOF.gsub(/^\s{12}/,'')
            require 'sinatra'
            require 'json'
            set :port, 8787
            def ok(data)
                [
                    200,
                    { 'Content-Type' => 'application/json' },
                    JSON.pretty_generate(data)
                ]
            end

            get '/foo.json' do
                ok(
                   {
                       '$doctype' => 'noms-v2',
                       '$body' => ["Data answer for foo command"]
                   }
                )
            end
            EOF
        end
        system("test/start-app-#{Process.pid}.sh")
        sleep 5
    end

    after(:all) do
        system("kill `ps -f | grep test-app-#{Process.pid}.rb | grep -v grep | awk '{ print $2 }'`")
        FileUtils.rm_r('test')
    end

    describe '.new' do
        context 'with local file' do
            before(:all) do
                @doc = NOMS::Command::Document.new(NOMS::Command::Window.new($0),
                                                   "file:///#{Dir.pwd}/test/foo.txt", [])
                @doc.fetch!
            end

            specify { expect(@doc.type).to eq 'text/plain' }
            specify { expect(@doc.body).to include 'Test output for local file' }
        end
    end

end

