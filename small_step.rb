# language Simple, using small-step semantics

# ============== Expression =================

class Number < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "< #{to_s} >"
  end

  def reduciable?
    false
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "< #{self} >"
  end

  def reduciable?
    false
  end
end

class Add < Struct.new(:left, :right)
  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "< #{to_s} >"
  end

  def reduciable?
    true
  end

  def reduce(environment)
    if left.reduciable?
      Add.new(left.reduce(environment), right)
    elsif right.reduciable?
      Add.new(left, right.reduce(environment))
    else
      Number.new(left.value + right.value)
    end
  end
end

class Multiply < Struct.new(:left, :right)
  def to_s
    "#{left} * #{right}"
  end
  
  def inspect
    "< #{to_s} >"
  end

  def reduciable?
    true
  end

  def reduce(environment)
    if left.reduciable?
      Multiply.new(left.reduce(environment), right)
    elsif right.reduciable?
      Multiply.new(left, right.reduce(environment))
    else
      Number.new(left.value * right.value)
    end
  end
end

class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end

  def inspect
    "< #{to_s} >"
  end

  def reduciable?
    true
  end

  def reduce(environment)
    environment[name]
  end
end

# each machine has an environment accordingly
class Machine < Struct.new(:expression, :environment)
  def step
    self.expression = expression.reduce(environment)
  end

  def run
    while expression.reduciable?
      puts expression
      step
    end
    puts expression
  end
end

# env = {"hello"=> Number.new(20)}
# machine = Machine.new(
#   Add.new(
#     Variable.new("hello"),
#     Multiply.new(Number.new(97), Number.new(41))
# ),env)
# machine.run


# ============== Statement =================

class DoNothing
  def to_s
    'do-nothing'
  end

  def inspect
    "< #{self} >"
  end

  def reduciable?
    false
  end

  def ==(other_statement)
    other_statement.instance_of? DoNothing
  end
end

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "< #{self} >"
  end

  def reduciable?
    true
  end

  def reduce(environment)
    if expression.reduciable?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge(name => expression.value )] # modify the environment
    end
  end
end

class Sequence < Struct.new(:first, :second)
  def to_s
    "#{first}; #{second}"
  end

  def inspect
    "< #{self} >"
  end

  def reduciable?
    true
  end

  def reduce(environment)
    case first
    when DoNothing.new
      [second, environment]
    else
      reduced_first, reduced_environment = first.reduce(environment)
      [Sequence.new(reduced_first, second), reduced_environment]
    end
  end
end

class If < Struct.new(:condition, :consequence, :alternative)
  def reduciable?
    true
  end

  def reduce(environment)
    if condition.reduciable?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    elsif condition.value
      [consequence, environment]# consequence.reduce(environment) # may be not reduciable
    else
      [alternative, environment]
    end
  end
end

class While < Struct.new(:condition, :body)
  def reduciable?
    true
  end

  def reduce(environment)
    [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
  end
end

Object.send(:remove_const, :Machine)

class Machine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end

  def run
    while statement.reduciable?
      puts self
      step
    end
    puts self
  end

  def to_s
    "< #{statement}, #{environment}>"
  end
end