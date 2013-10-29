# Pushdown Automata: finite state machine with a built-in stack
class Stack
  def initialize(items = [])
    @items = items
  end

  def top
    @items[-1]
  end

  def size
    @items.size
  end

  def push(item)
    @items << item
  end

  def pop
    @items.delete_at(-1)
  end

  def empty?
    @items.empty?
  end
end

class PDARule < Struct.new(:state,:character, :next_state, :pop_character, :push_characters)

end