require 'sinatra/base'

class AssetServer < Sinatra::Application
  configure do
    set :port, 9006
  end

  get 'htmlcs.js' do
    send_file "vendor/HTMLCS.js";
  end
end

AssetServer.run!