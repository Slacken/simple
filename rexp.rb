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

  def matched?(string)
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
    rulebook = NFARuleBook.new([])
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
    rulebook = NFARuleBook.new([FARule.new(start_state, character, accept_state)])
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
    rulebook = left_nfa_design.rulebook + right_nfa_design.rulebook + left_nfa_design.accept_states.map{|state| FARule.new(state, nil, right_nfa_design.start_state)}
    
    NFADesign.new(start_state, accept_states, rulebook)
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
    rulebook = left_nfa_design.rulebook + right_nfa_design.rulebook
    rulebook << FARule.new(start_state, nil, left_nfa_design.start_state)
    rulebook << FARule.new(start_state, nil, right_nfa_design.start_state)
    rulebook += (left_nfa_design.accept_states + right_nfa_design.accept_states).map{|state| FARule.new(state, nil, accept_state )}

    NFADesign.new(start_state, Set[accept_state], rulebook)
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
    
  end
end

# puts Concatenate.new(Literal.new('a'), Repeat.new(Literal.new('b'))).inspect
# puts Empty.new.to_nfa_design.accepts?('')
# puts Literal.new('a').to_nfa_design.accepts?('b')
puts Choose.new(Literal.new('a'), Literal.new('b')).inspect