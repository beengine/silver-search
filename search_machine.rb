require 'sinatra/json'
require './parser_machine'

class SearchMachine
  def initialize(data_file)
    @data = JSON.parse(File.read(data_file))
    @parsed = @data.map{ |lang| "#{lang['Name']} #{lang['Type']} #{lang['Designed by']}"}
    @data.map!.with_index { |lang, i| lang.merge(id: i) }
  end

  def find(query)
    pm = ParserMachine.new(query)
    results = []
    @parsed.each_with_index do |lang, index|
      if !pm.regexes[:negative] || !pm.regexes[:negative].match?(lang)
        if pm.regexes[:exact_match].match?(lang)
          results << @data[index].merge(relevance: 0)
        elsif pm.regexes[:any_order].match?(lang)
          results << @data[index].merge(relevance: 1)
        elsif pm.regexes[:any_word].match?(lang)
          results << @data[index].merge(relevance: 2)
        end
      end
    end
    results
  end
end
