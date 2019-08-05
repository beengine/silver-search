require 'sinatra/json'
require './parser_machine'

class SearchMachine
  def initialize(data_file)
    @parsed = JSON.parse(File.read(data_file)).map do |lang| 
      { 
        search_string: lang.values.join(' '), #all fields to one for scanning
        data: lang
      }
    end
  end

  def find(query)
    pm = ParserMachine.new(query)
    results = []
    @parsed.each do |lang|
      unless pm.regexes[:negative] && pm.regexes[:negative].match?(lang[:search_string])
        if pm.regexes[:exact_match].match?(lang[:search_string])
          results << lang[:data].merge(relevance: 0) # adding language with highest relevance level to results
        elsif pm.regexes[:any_order].match?(lang[:search_string])
          results << lang[:data].merge(relevance: 1) # adding language with mid relevance level
        elsif pm.regexes[:any_word].match?(lang[:search_string])
          results << lang[:data].merge(relevance: 2) # adding language with low relevance level
        end
      end
    end
    results
  end
end
