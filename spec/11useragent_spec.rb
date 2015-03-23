#!/usr/bin/env rspec

require 'spec_helper'

require 'noms/command/useragent'

def get_generated(response)
    Time.httpdate(JSON.parse(response.body)['generated'])
end

describe 'NOMS::Command::UserAgent' do
    before(:all) do
        setup_fixture
        start_server
    end

    after(:all) do
        stop_server
        teardown_fixture
    end

    context 'when caching' do

        describe '.request' do

            before(:each) do
                @ua = NOMS::Command::UserAgent.new :max_age => 10, :cache => true
                @ua.clear_cache!
            end

            it 'loads fresh content' do
                response, = @ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response.from_cache?).to be_falsey
                generated = get_generated(response)
                expect(Time.now - generated).to be <= 1
            end

            it 'loads cached content' do
                response0, = @ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response0.from_cache?).to be_falsey
                generated0 = get_generated response0

                sleep 2
                response1, = @ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response1.from_cache?).to be_truthy
                generated1 = get_generated response1

                expect(generated1).to eq generated0
            end

            it 'refetches cached content' do
                response0, = @ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response0.from_cache?).to be_falsey
                generated0 = get_generated response0

                sleep 5
                response2, = @ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response0.from_cache?).to be_falsey
                generated1 = get_generated response1

                expect(Time.now - generated).to be <= 1
            end

            it 'revalidates cached content with last-modified' do
                response0, = @ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response0.from_cache?).to be_falsey
                generated0 = get_generated response0

                sleep 5
                response1, = @ua.request('GET', 'http://localhost:8787/static/last-modified')
                expect(response1.from_cache?).to be_truthy
                generated1 = get_generated response1

                expect(generated1).to eq generated0
            end

            it 'revalidates cached content' do
                response0, = @ua.request('GET', 'http://localhost:8787/static/expires-2-constant')
                expect(response0.from_cache?).to be_falsey
                generated0 = get_generated response0

                sleep 3
                response1, = @ua.request('GET', 'http://localhost:8787/static/expires-2-constant')
                expect(response1.from_cache?).to be_truthy
                generated1 = get_generated response1

                expect(generated1).to eq generated0
            end

            it 'refuses to cache longer than :max_age' do
                response0, = @ua.request('GET', 'http://localhost:8787/static/long-cache')
                expect(response0.from_cache?).to be_falsey
                generated0 = get_generated response0

                sleep 5
                response1, = @ua.request('GET', 'http://localhost:8787/static/long-cache')
                expect(response1.from_cache?).to be_truthy
                generated1 = get_generated response1

                expect(generated1).to eq generated0

                sleep 6
                response2, = @ua.request('GET', 'http://localhost:8787/static/long-cache')
                expect(response2.from_cache?).to be_falsey
                generated2 = get_generated response2

                expect(generated2 - Time.now).to be <= 1
            end

            it 'refuses to cache when directed' do
                ua = NOMS::Command::UserAgent.new :cache => false
                response0, = ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response0.from_cache?).to be_falsey
                generated0 = get_generated response0

                sleep 2
                response1, = ua.request('GET', 'http://localhost:8787/static/expires-4')
                expect(response1.from_cache?).to be_falsey
                generated1 = get_generated response1

                expect(generated1).to_not eq generated0
                expect(generated0 - Time.now).to be <= 1
            end

        end

    end

end
