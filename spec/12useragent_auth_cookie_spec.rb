#!/usr/bin/env rspec

require 'spec_helper'

require 'noms/command/useragent'

describe NOMS::Command::UserAgent do

    before(:all) do
        setup_fixture
        start_server
    end

    after(:all) do
        teardown_fixture
        stop_server
    end

    context 'when using cookies' do

        describe '#request' do

            before(:each) do
                @cookie_jar = File.join(NOMS::Command.home, 'cookies.txt')
                File.unlink @cookie_jar if File.exist? @cookie_jar
                @ua = NOMS::Command::UserAgent.new 'http://localhost:8787/', :specified_identities => ['test/identity'],
                    :cache => false
            end

            it 'gets cookie-authorized document' do
                response, = @ua.get 'http://localhost:8787/cookie/home'
                result = JSON.parse(response.body)
                expect(result['cookie_user']).to eq 'testuser'
            end

            it 'persists cookies between invocations' do
                response0, = @ua.get 'http://localhost:8787/cookie/home'
                result0 = JSON.parse(response0.body)

                expect(File.exist? @cookie_jar).to be_truthy

                ua = NOMS::Command::UserAgent.new 'http://localhost:8787/', :cache => false
                response1, = ua.get 'http://localhost:8787/cookie/home'
                result1 = JSON.parse(response1.body)

                expect(result1).to have_key 'cookie_user'
                expect(result1['cookie_user']).to eq 'testuser'
            end
        end

    end

end
