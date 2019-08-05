require 'aasm'
#parses user query to slices and generates regexes for data search
#to parse user query finite-state machine is used
#aasm gem used to provide state machine functionality
class ParserMachine

  include AASM

  attr_accessor :regexes

  aasm do
    state :nill, initial: true, enter: :skip_char   # initial state, state when parser outside of any slice
    state :word, enter: :write_char_to_slice        # adding ordinary word
    state :exact_match, enter: :write_char_to_slice # adding exact match
    state :negative_thing                           # happens right after dash, may transition to negative word or negative exact match
    state :negative_word, enter: :write_char_to_negative_slice        # adding negative word
    state :negative_exact_match, enter: :write_char_to_negative_slice # adding negative exact match, like -"something lame"
    state :end # end of query

    after_all_events :run_next_step

    event :space do
      transitions from: [:nill, :word, :negative_thing, :negative_word], to: :nill
      transitions from: :exact_match, to: :exact_match
      transitions from: :negative_exact_match, to: :negative_exact_match
    end

    event :dash do
      transitions from: :nill, to: :negative_thing, after: [:skip_char, :open_negative_slice]
      transitions from: :word, to: :word
      transitions from: [:negative_word, :negative_thing], to: :negative_word
      transitions from: :exact_match, to: :exact_match
      transitions from: :negative_exact_match, to: :negative_exact_match
    end

    event :quote do
      transitions from: :nill, to: :exact_match, after: [:skip_char, :open_slice]
      transitions from: [:exact_match, :negative_exact_match], to: :nill
      transitions from: :negative_thing, to: :negative_exact_match, after: :skip_char
      transitions from: :word, to: :word
      transitions from: :negative_word, to: :negative_word
    end

    event :other_char do
      transitions from: :nill, to: :word, after: :open_slice
      transitions from: :word, to: :word
      transitions from: :exact_match, to: :exact_match
      transitions from: [:negative_word, :negative_thing], to: :negative_word
      transitions from: :negative_exact_match, to: :negative_exact_match
    end

    event :eos do
      transitions from: [:nill, :word, :exact_match, :negative_thing, :negative_word, :negative_exact_match], to: :end
    end
  end

  def initialize(query)
    @query = query
    @slices = []
    @negative_slices = []
    @char = @query.slice!(0)
    run_next_step
    generate_regexes
  end

  private

  def write_char_to_slice
    @slices.last << @char
    @char = @query.slice!(0)
  end

  def write_char_to_negative_slice
    @negative_slices.last << @char
    @char = @query.slice!(0)
  end

  def skip_char
    @char = @query.slice!(0)
  end

  def open_slice
    @slices << ''
  end

  def open_negative_slice
    @negative_slices << ''
  end

  def run_next_step # taking next char to analyze
    return if self.end?
    case @char
    when '-'
      self.dash
    when '"'
      self.quote
    when ' '
      self.space
    when nil
      self.eos
    else
      self.other_char
    end
  end

  def generate_regexes
    @regexes = {
      exact_match: Regexp.new(@slices.join(' '), true),                                # exact match, all slices in query to match data
      any_order:   Regexp.new("^#{@slices.map{|s| '(?=.*' + s + ')'}.join}.*$", true), # regex to match when all slices match but in arbitrary order
      any_word:    Regexp.new(@slices.join('|'), true)                                 # regex to match any word in query
    }
    @regexes[:negative] = Regexp.new(@negative_slices.join('|'), true) unless @negative_slices.empty? #negative regex
  end
end
