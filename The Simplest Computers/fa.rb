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

  # for NFA, next may be multiple states
  def next_states(states, character)
    states.flat_map do |state|
      rules.select{|rule| rule.aplies_to?(state, character) }.map(&:next_state) 
    end.to_set
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
    string.each{|c| read_character(c)}
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

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    (current_states & accept_states).any?
  end

  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.each{ |c| read_character(c) }
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