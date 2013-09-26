# Regular Expression

require './fa'

module Pattern
  def inspect
    "/#{self}/"
  end

  def bracket(outer_precedence) # wrap with bracket or not
    if precedence < outer_precedence
      "(#{to_s})"
    else
      to_s
    end
  end

  def matches?(string)
    to_nfa_design.accepts?(string)
  end
end

class Empty
  include Pattern

  def to_s
    ''
  end

  def precedence
    3
  end

  def to_nfa_design
    start_state = Object.new
    accept_states = Set[start_state]
    rulebook = NFARuleBook.new(Set[])
    NFADesign.new(start_state, accept_states, rulebook)
  end
end

class Literal < Struct.new(:character)
  include Pattern
  
  def to_s
    character
  end

  def precedence
    3
  end

  def to_nfa_design
    start_state = Object.new
    accept_state = Object.new
    rulebook = NFARuleBook.new(Set[FARule.new(start_state, character, accept_state)])
    NFADesign.new(start_state, Set[accept_state], rulebook)
  end
end

class Concatenate < Struct.new(:left, :right)
  include Pattern

  def to_s
    [left, right].map{|pattern| pattern.bracket(precedence) }.join
  end

  def precedence
    1
  end

  def to_nfa_design
    left_nfa_design, right_nfa_design = left.to_nfa_design, right.to_nfa_design
    
    start_state = left_nfa_design.start_state
    accept_states = right_nfa_design.accept_states
    rules = left_nfa_design.rulebook.rules + 
               right_nfa_design.rulebook.rules + 
               left_nfa_design.accept_states.map{|state| FARule.new(state, nil, right_nfa_design.start_state)}
    
    NFADesign.new(start_state, accept_states, NFARuleBook.new(rules))
  end
end

class Choose < Struct.new(:left, :right)
  include Pattern

  def to_s
    [left, right].map{|pattern| pattern.bracket(precedence) }.join("|")
  end

  def precedence
    0
  end

  def to_nfa_design
    left_nfa_design, right_nfa_design = left.to_nfa_design, right.to_nfa_design
    
    start_state = Object.new
    accept_state = Object.new
    rules = left_nfa_design.rulebook.rules + right_nfa_design.rulebook.rules
    rules << FARule.new(start_state, nil, left_nfa_design.start_state)
    rules << FARule.new(start_state, nil, right_nfa_design.start_state)
    rules += (left_nfa_design.accept_states + right_nfa_design.accept_states).map{|state| FARule.new(state, nil, accept_state )}

    NFADesign.new(start_state, Set[accept_state], NFARuleBook.new(rules))
  end
end

class Repeat < Struct.new(:pattern)
  include Pattern

  def to_s
    pattern.bracket(precedence) + "*"
  end

  def precedence
    2
  end

  def to_nfa_design
    pattern_nfa_design = pattern.to_nfa_design
    
    start_state = pattern_nfa_design.start_state
    accept_states = pattern_nfa_design.accept_states
    rules = pattern_nfa_design.rulebook.rules + accept_states.map{|state| FARule.new(state, nil, start_state)}

    NFADesign.new(start_state, accept_states, NFARuleBook.new(rules))
  end
end

# class Object
#   def inspect
#     "<#{object_id%1000}>"
#   end
# end

# puts Concatenate.new(Literal.new('a'), Repeat.new(Literal.new('b'))).inspect
# puts Empty.new.to_nfa_design.accepts?('')
# puts Literal.new('a').to_nfa_design.accepts?('b')
# puts Concatenate.new(Literal.new('a'), Literal.new('b')).inspect
# nfa = Concatenate.new(Literal.new('a'), Repeat.new(Literal.new('b'))).to_nfa_design
# puts nfa.accepts?('abbbba')