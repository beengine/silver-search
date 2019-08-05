require 'sinatra/json'
require './parser_machine'

class SearchMachine
  def initialize(data_file)
    @data = JSON.parse(File.read(data_file))
    @parsed = @data.map{ |lang| "#{lang['Name']} #{lang['Type']} #{lang['Designed by']}"} # all fields to one for scanning
  end

  def find(query)
    pm = ParserMachine.new(query)
    results = []
    @parsed.each_with_index do |lang, index|
      unless pm.regexes[:negative] && pm.regexes[:negative].match?(lang)
        if pm.regexes[:exact_match].match?(lang)
          results << @data[index].merge(relevance: 0) # adding language with highest relevance level to results
        elsif pm.regexes[:any_order].match?(lang)
          results << @data[index].merge(relevance: 1) # adding language with mid relevance level
        elsif pm.regexes[:any_word].match?(lang)
          results << @data[index].merge(relevance: 2) # adding language with low relevance level
        end
      end
    end
    results
  end
end
