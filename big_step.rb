
# ==== expression ====

class Number < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    self
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    self
  end
end

class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    environment[name]
  end
end

class Add < Struct.new(:left, :right)
  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "< #{to_s} >"
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end
end

class Multiply < Struct.new(:left, :right)
  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end
end

class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "< #{to_s} >"
  end

  def evaluate(environment)
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end
end

class DoNothing
  def to_s
    "do-nothing"
  end

  def inspect
    "< #{self}>"
  end

  def evaluate(environment)
    environment
  end
end

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    environment.merge({name => expression.evaluate(environment)})
  end
end

class Sequence < Struct.new(:first, :second) # first/second is instance of  Assign or DoNothing
  def to_s
    "#{first};#{second}"
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    second.evaluate(first.evaluate(environment))
  end
end

class If < Struct.new(:condition, :consequence, :alternative)
  def to_s
    "if #{condition} then #{consequence} else #{alternative}"
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    if condition.evaluate(environment) == Boolean.new(true)
      consequence.evaluate(environment)
    else
      alternative.evaluate(environment)
    end
  end
end

class While < Struct.new(:condition, :body)
  def to_s
    "while #{condition} do #{body}"
  end

  def inspect
    "< #{self} >"
  end

  def evaluate(environment)
    if condition.evaluate(environment) == Boolean.new(true)
      evaluate(body.evaluate(body)) # While.new(condition, body).evaluate(body.evaluate(body))
    else
      environment # DoNothing.new.evaluate(environment)
    end
  end
end

# If.new(
#   LessThan.new(Variable.new(:x), Number.new(34)), 
#   Sequence.new(DoNothing.new, Assign.new(:y, Number.new(20))),
#   Sequence.new(DoNothing.new, Assign.new(:y, Number.new(21)))
# ).evaluate({x: Number.new(12), y: Number.new(0)})