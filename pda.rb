# Pushdown Automata: finite state machine with a built-in stack
class Stack < Struct.new(:contents)
  def top
    contents[0]
  end

  def size
    contents.size
  end

  def push(item)
    Stack.new([item] + contents)
  end

  def pop
    Stack.new(contents.drop(1))
  end

  def empty?
    contents.empty?
  end

  def inspect
    "#<Stack (#{top})#{contents.drop(1).join}>"
  end
end

# store current information
class PDAConfiguration < Struct.new(:state, :stack)
  STUCK_STATE = Object.new
  def stuck
    PDAConfiguration.new(STUCK_STATE, stack)
  end

  def stuck?
    state == STUCK_STATE
  end
end

# push_characters is as a whole to push
class PDARule < Struct.new(:state, :character, :next_state, :pop_character, :push_characters)
  def aplies_to?(configuration, character)
    self.state == configuration.state && 
      self.character == character && 
      self.pop_character == configuration.stack.top
  end

  def follow(configuration)
    PDAConfiguration.new(next_state, next_stack(configuration.stack))
  end

  def next_stack(stack)
    popped_stack = stack.pop
    push_characters.reverse.inject(popped_stack) { |stack, character| stack.push(character) }
  end
end

class DPDARuleBook < Struct.new(:rules)
  def next_configuration(configuration, character)
    rule_for(configuration, character).follow(configuration)
  end

  def rule_for(configuration, character)
    rules.detect{|rule| rule.aplies_to?(configuration, character)}
  end

  def aplies_to?(configuration, character)
    !rule_for(configuration, character).nil?
  end

  def follow_free_moves(configuration)
    if aplies_to?(configuration, nil)
      follow_free_moves(next_configuration(configuration, nil))
    else
      configuration
    end
  end
end

require 'set'
class NPDARuleBook < Struct.new(:rules)
  def next_configurations(configurations, character) # next configurations of current configurations
    configurations.flat_map{|configuration| follow_rules_for(configuration, character)}.to_set
  end

  def rules_for(configuration, character)
    rules.select{|rule| rule.aplies_to?(configuration, character)}
  end

  def follow_rules_for(configuration, character)
    rules_for(configuration, character).map{|rule| rule.follow(configuration)}
  end

  def follow_free_moves(configurations)
    more_configurations = next_configurations(configurations, nil)
    if more_configurations.subset?(configurations)
      configurations
    else
      follow_free_moves(more_configurations + configurations)
    end
  end
end

class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
  def current_configuration
    rulebook.follow_free_moves(super)
  end

  def next_configuration(character)
    if rulebook.aplies_to?(current_configuration, character)
      rulebook.next_configuration(current_configuration, character)
    else # not find matched rule
      current_configuration.stuck
    end
  end

  def accepting?
    accept_states.include?( current_configuration.state)
  end

  def stuck?
    current_configuration.stuck?
  end

  def read_character(character)
    self.current_configuration = next_configuration(character)
  end

  def read_string(string)
    string.chars.each{|character| read_character(character) unless stuck? }
  end
end

class NPDA < Struct.new(:current_configurations, :accept_states, :rulebook)
  def current_configurations
    rulebook.follow_free_moves(super)
  end

  def accepting?
    current_configurations.any?{|configuration| accept_states.include?(configuration.state)}
  end

  def read_character(character)
    self.current_configurations = rulebook.next_configurations(current_configurations, character)
  end

  def read_string(string)
    string.chars.each{|character| read_character(character)}
  end
end

class DPDADesign < Struct.new(:start_state, :bottom_character, :accept_states, :rulebook)
  def to_dpda
    start_stack = Stack.new([bottom_character])
    DPDA.new(PDAConfiguration.new(start_state, start_stack), accept_states, rulebook)
  end

  def accepts?(string)
    to_dpda.tap{|dpda| dpda.read_string(string) }.accepting?
  end
end

class NPDADesign < Struct.new(:start_state, :bottom_character, :accept_states, :rulebook)
  def to_npda
    start_stack = Stack.new([bottom_character])
    NPDA.new(Set[PDAConfiguration.new(start_state, start_stack)], accept_states, rulebook)
  end

  def accepts?(string)
    to_npda.tap{|npda| npda.read_string(string) }.accepting?
  end
end

# rulebook = DPDARuleBook.new([
#   PDARule.new(1,'a', 2, '$',['a','$']),
#   PDARule.new(1,'b', 2, '$',['b','$']),
#   PDARule.new(2,'a', 2, 'a',['a','a']),
#   PDARule.new(2,'b', 2, 'b',['b','b']),
#   PDARule.new(2,'a', 2, 'b',[]),
#   PDARule.new(2,'b', 2, 'a',[]),
#   PDARule.new(2,nil, 1, '$',['$']) # free move
# ])
# configuration = PDAConfiguration.new(1, Stack.new(['$']))

# dpda = DPDA.new(configuration, [1], rulebook)
# puts dpda.accepting?
# dpda.read_string('abba')
# puts dpda.accepting?

