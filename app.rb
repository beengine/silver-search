require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?
require './search_machine'

configure do
  SM = SearchMachine.new('data.json')
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  if params[:query]
    erb :home, locals: {query: params[:query], results: SM.find(params[:query].dup)}
  else
    erb :home, locals: {query: nil, results: []}
  end
end
