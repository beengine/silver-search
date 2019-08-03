require 'sinatra'
require 'json'

configure do
  JSON_FILE = File.read('data.json')
  DATA = JSON.parse(JSON_FILE)
end

helpers do
end

get '/' do
  erb :home
end
