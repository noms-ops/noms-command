require 'sinatra/base'
require 'json'

# Implement Do Not Call List Example REST application
# and static file server
class DNC < Sinatra::Application

    set :port, 8787
    set :root, File.expand_path("#{File.dirname(__FILE__)}")
    enable :static

    File.open(File.join(settings.root, 'dnc.pid'), 'w') {|f| f.puts Process.pid }

    def load_data
        JSON.load(File.open(File.join(settings.root, 'public', 'files', 'data.json')))
    end

    def write_data(data)
        File.open(File.join(settings.root, 'public', 'files', 'data.json'), 'w') { |fh| fh << data.to_json }
    end

    helpers do
        def require_auth
            return if authorized?
            headers['WWW-Authenticate'] = 'Basic realm="Authorization Required"'
            halt 401, "Not authorized\n"
        end

        def authorized?
            @auth ||=  Rack::Auth::Basic::Request.new(request.env)
            @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['testuser', 'testpass']
        end
    end

    get '/readme' do
        redirect 'https://raw.githubusercontent.com/en-jbrinkley/noms-command/master/README.rst', 'README'
    end

    get '/dnc' do
        data = load_data
        if request.query_string.empty?
            [ 200, { 'Content-type' => 'application/json'},
                JSON.pretty_generate(data) ]
        else
            [ 200, { 'Content-type' => 'application/json' },
                JSON.pretty_generate(
                                     data.select do |item|
                                         params.keys.all? { |k| item[k.to_s] && item[k.to_s].to_s === params[k] }
                                     end)
            ]
        end
    end

    get '/dnc/:id' do
        data = load_data
        object = data.find { |e| e['id'] == params[:id].to_i }
        if object
            [ 200, { 'Content-type' => 'application/json' },
                JSON.pretty_generate(object) ]
        else
            404
        end
    end

    post '/dnc' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        puts "POST for object: #{new_object.inspect}"

        data = load_data
        # How unsafe is this?
        new_object['id'] = data.map { |e| e['id'] }.max + 1
        data << new_object
        write_data data

        [ 201, { 'Content-type' => 'application/json' },
            JSON.pretty_generate(new_object) ]
    end

    put '/dnc/:id' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        data = load_data
        new_data = data.reject { |e| e['id'] == params[:id].to_i }
        if new_data.size == data.size
            404
        else
            new_object['id'] = params[:id].to_i
            new_data << new_object
            write_data new_data

            [ 200, { 'Content-type' => 'application/json' },
                JSON.pretty_generate(new_object) ]
        end
    end

    delete '/dnc/:id' do
        data = load_data
        new_data = data.reject { |e| e['id'] == params[:id].to_i }

        if new_data.size == data.size
            404
        else
            write_data new_data
            204
        end
    end

    get '/alt/dnc.json' do
        redirect to('/dnc.json')
    end

    get '/auth/dnc.json' do
        require_auth
        redirect to('/dnc.json')
    end

    get '/auth/ok' do
        require_auth
        "SUCCESS"
    end


    run! if app_file = $0

end
