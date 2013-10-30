# Parser for Simple
class LexicalAnalyzer < Struct.new(:string)
  GRAMMAR = [
    {token: 'i', pattern: /if/},
    {token: 'e', pattern: /else/},
    {token: 'w', pattern: /while/},
    {token: 'd', pattern: /do-nothing/},
    {token: '(', pattern: /\(/},
    {token: ')', pattern: /\)/},
    {token: '{', pattern: /\{/},
    {token: '}', pattern: /\}/},
    {token: ';', pattern: /;/},
    {token: '=', pattern: /=/},
    {token: '+', pattern: /\+/},
    {token: '*', pattern: /\*/},
    {token: '<', pattern: /</},
    {token: 'n', pattern: /[0-9]+/},
    {token: 'b', pattern: /true|false/},
    {token: 'v', pattern: /[a-z]+/},
  ] # use proper data structure is better

  def analyze
    [].tap do |tokens|
      while more_tokens?
        tokens.push(next_token)
      end
    end
  end

  def more_tokens?
    !string.empty?
  end

  def next_token
    rule, match = rule_matching(string)
    self.string = string_after(match)
    rule[:token]
  end

  def rule_matching(string)
    rules_with_matches = GRAMMAR.map{|rule| 
        [rule, match_at_beginning(rule[:pattern], string) ]
      }.reject{|rule, match| match.nil?}
    rule_with_longest_match(rules_with_matches)
  end

  def match_at_beginning(pattern, string)
    /\A#{pattern}/.match(string)
  end

  # considering variable name may contain keyword
  def rule_with_longest_match(rules_with_matches)
    rules_with_matches.max_by{|rule, match| match.to_s.length }
  end

  def string_after(match)
    match.post_match.lstrip
  end
end

require './pda'
start_rule = PDARule.new(1, nil, 2, '$', ['S','$'])
# S<statement>, W<while>, A<assign>, E<expression>,L<less-than>, M<multiply>, T<term>
symbol_rules = [
  PDARule.new(2, nil, 2, 'S', ['W']), PDARule.new(2, nil, 2, 'S', ['A']), # S->W|A
  PDARule.new(2, nil, 2, 'W',['w','(','E',')','{','S','}']), # W->w(E){S}
  PDARule.new(2, nil, 2, 'A', ['v','=','E']), # A->v=E
  PDARule.new(2, nil, 2, 'E', ['L']), # E->L
  PDARule.new(2, nil, 2, 'L', ['M','<','L']), PDARule.new(2, nil, 2, 'L', ['M']), # L-> M<L | M
  PDARule.new(2, nil, 2, 'M', ['T','*','M']),PDARule.new(2, nil, 2, 'M', ['T']), # M-> T*M | T
  PDARule.new(2, nil, 2, 'T', ['n']),PDARule.new(2, nil, 2, 'T', ['v']) # T->n|v
]
token_rules = LexicalAnalyzer::GRAMMAR.map{|rule| PDARule.new(2, rule[:token], 2, rule[:token], [])}
stop_rule = PDARule.new(2, nil, 3, '$', ['$'])

rulebook = NPDARuleBook.new([start_rule, stop_rule] + symbol_rules + token_rules)
npda_design = NPDADesign.new(1, '$', [3], rulebook)

token_string = LexicalAnalyzer.new('while(x < 5){x = x * 3}').analyze.join
puts npda_design.accepts? token_string
