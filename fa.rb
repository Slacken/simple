# Finite Automata: DFA & NFA

require 'set'

# free move when character is nil
class FARule < Struct.new(:state, :character, :next_state)
  def aplies_to?(state, character)
    self.state == state && self.character == character
  end
end

class DFARuleBook < Struct.new(:rules)
  def next_state(state, character)
    rule = rules.detect{|r| r.aplies_to?(state, character) } # rule should not be nil
    rule && rule.next_state 
  end
end

class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include? current_state
  end

  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end

  def read_string(string)
    string.each_char{|c| read_character(c)}
  end
end

class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end

  def accepts?(string)
    to_dfa.tap{|dfa| dfa.read_string(string) }.accepting?
  end
end

class NFARuleBook < Struct.new(:rules)
  # for NFA, next may be multiple states
  def next_states(states, character)
    states.flat_map do |state|
      rules.select{|rule| rule.aplies_to?(state, character) }.map(&:next_state) 
    end.to_set
  end
   
  alias :next_states_without_free_move :next_states

  def next_states(states, character)
    next_states_without_free_move(states, nil) + next_states_without_free_move(states, character)
  end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end

  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.each_char{ |c| read_character(c) }
  end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end

  def accepts?(string)
    to_nfa.tap{|nfa| nfa.read_string(string) }.accepting?
  end
end

# book = NFARuleBook.new([FARule.new(1,'a',2), FARule.new(1,'b',3),FARule.new(2,'a',3),FARule.new(1,'a',3),FARule.new(3,nil,4)])
# book.next_states([1,3],'a')
# nfa = NFADesign.new(1, Set[4], book)
# nfa.accepts?('aa')