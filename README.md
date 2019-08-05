## Silver Search

[DEMO](http://silversearch.herokuapp.com/)

* Ruby 2.6.3
* Sinatra 2.0.5
* aasm 5.0.5


Silver Search contains two classes, which provide search - SearchMachine and ParserMachine.

### ParserMachine

ParserMachine parses user query to slices and generates regexes for data search. Slice is an atomic object in our implementation. Generally, parser works with 4 types of "data": words, exact mathces, negative words and negative exact matches.
* Word is just a word, surrounded with spaces, e. g. `lisp`
* Exact match can contain any chars. It surronds with double quotes, e. g. `"Richard Blomme"`
* Negative word is used to exclude matching results. Negative words start with dash `-`, e. g. `-compiled`
* Negative exact match combines exact matches and negative words. Allows to exlude results with any exact phrase. Looks like `-"Apple inc."`
As result, we get positive and negative slices.

After parsing ParserMachine generates four regexes: `exact_match`, `any_order`, `any_word`, `negative`.
* `exact_match` takes exact query (except negative slices) and tries to find a match as is.
* `any_order` does the same, but slices might be in arbitrary order.
* `any_word` tries to find any slice from query.
* `negative` is used to exlude langs from search by negative slices.

### SearchMachine

SearchMachine fetches data, takes user query and returns result with relevance index.


