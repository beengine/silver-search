require 'aasm'
class ParserMachine

  include AASM

  attr_accessor :regexes

  aasm do
    state :nill, initial: true, enter: :skip_char
    state :word, enter: :write_char_to_slice
    state :exact_match, enter: :write_char_to_slice
    state :negative_thing
    state :negative_word, enter: :write_char_to_negative_slice
    state :negative_exact_match, enter: :write_char_to_negative_slice
    state :end

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

    event :eof do
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

  def run_next_step
    return if self.end?
    case @char
    when '-'
      self.dash
    when '"'
      self.quote
    when ' '
      self.space
    when nil
      self.eof
    else
      self.other_char
    end
  end

  def generate_regexes
    @regexes = {
      exact_match: Regexp.new(@slices.join(' '), true),
      any_order:   Regexp.new("^#{@slices.map{|s| '(?=.*' + s + ')'}.join}.*$", true),
      any_word:    Regexp.new(@slices.join('|'), true)
    }
    @regexes[:negative] = Regexp.new(@negative_slices.join('|'), true) unless @negative_slices.empty?
  end
end
