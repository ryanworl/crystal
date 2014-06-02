#!/usr/bin/env bin/crystal --run
require "../../spec_helper"

describe "Type inference: closure" do
  it "gives error when doing yield inside fun literal" do
    assert_error "-> { yield }", "can't yield from function literal"
  end

  it "marks variable as closured in program" do
    result = assert_type("x = 1; -> { x }; x") { int32 }
    program = result.program
    var = program.vars["x"]
    var.closured.should be_true
  end

  it "marks variable as closured in program on assign" do
    result = assert_type("x = 1; -> { x = 1 }; x") { int32 }
    program = result.program
    var = program.vars["x"]
    var.closured.should be_true
  end

  it "marks variable as closured in def" do
    result = assert_type("def foo; x = 1; -> { x }; 1; end; foo") { int32 }
    node = result.node as Expressions
    call = node.expressions.last as Call
    target_def = call.target_def
    var = target_def.vars.not_nil!["x"]
    var.closured.should be_true
  end

  it "marks variable as closured in block" do
    result = assert_type("
      def foo
        yield
      end

      foo do
        x = 1
        -> { x }
        1
      end
      ") { int32 }
    node = result.node as Expressions
    call = node.expressions.last as Call
    block = call.block.not_nil!
    var = block.vars.not_nil!["x"]
    var.closured.should be_true
  end

  it "unifies types of closured var (1)" do
    assert_type("
      a = 1
      f = -> { a }
      a = 2.5
      a
      ") { union_of(int32, float64) }
  end

  it "unifies types of closured var (2)" do
    assert_type("
      a = 1
      f = -> { a }
      a = 2.5
      f.call
      ") { union_of(int32, float64) }
  end

  it "marks variable as closured inside block in fun" do
    result = assert_type("
      def foo
        yield
      end

      a = 1
      -> { foo { a } }
      a
      ") { int32 }
    program = result.program
    var = program.vars.not_nil!["a"]
    var.closured.should be_true
  end

  it "doesn't mark var as closured if only used in block" do
    result = assert_type("
      x = 1

      def foo
        yield
      end

      foo { x }
      ") { int32 }
    program = result.program
    var = program.vars["x"]
    var.closured.should be_false
  end

  it "doesn't mark var as closured if only used in two block" do
    result = assert_type("
      def foo
        yield
      end

      foo do
        x = 1
        foo do
          x
        end
      end
      ") { int32 }
    node = result.node as Expressions
    call = node[1] as Call
    block = call.block.not_nil!
    var = block.vars.not_nil!["x"]
    var.closured.should be_false
  end

  it "doesn't mark self var as closured, but marks method as self closured" do
    result = assert_type("
      class Foo
        def foo
          -> { self }
        end
      end

      Foo.new.foo
      1
    ") { int32 }
    node = result.node as Expressions
    call = node.expressions[-2] as Call
    target_def = call.target_def
    var = target_def.vars.not_nil!["self"]
    var.closured.should be_false
    target_def.self_closured.should be_true
  end

  it "marks method as self closured if instance var is read" do
    result = assert_type("
      class Foo
        def foo
          -> { @x }
        end
      end

      Foo.new.foo
      1
    ") { int32 }
    node = result.node as Expressions
    call = node.expressions[-2] as Call
    call.target_def.self_closured.should be_true
  end

  it "marks method as self closured if instance var is written" do
    result = assert_type("
      class Foo
        def foo
          -> { @x = 1 }
        end
      end

      Foo.new.foo
      1
    ") { int32 }
    node = result.node as Expressions
    call = node.expressions[-2] as Call
    call.target_def.self_closured.should be_true
  end

  it "marks method as self closured if explicit self call is made" do
    result = assert_type("
      class Foo
        def foo
          -> { self.bar }
        end

        def bar
        end
      end

      Foo.new.foo
      1
    ") { int32 }
    node = result.node as Expressions
    call = node.expressions[-2] as Call
    call.target_def.self_closured.should be_true
  end

  it "marks method as self closured if implicit self call is made" do
    result = assert_type("
      class Foo
        def foo
          -> { bar }
        end

        def bar
        end
      end

      Foo.new.foo
      1
    ") { int32 }
    node = result.node as Expressions
    call = node.expressions[-2] as Call
    call.target_def.self_closured.should be_true
  end

  it "errors if sending closured fun literal to C" do
    assert_error %(
      lib C
        fun foo(callback : ->)
      end

      a = 1
      C.foo(-> { a })
      ),
      "can't send closure to C function"
  end

  it "errors if sending closured fun pointer to C (1)" do
    assert_error %(
      lib C
        fun foo(callback : ->)
      end

      class Foo
        def foo
          C.foo(->bar)
        end

        def bar
        end
      end

      Foo.new.foo
      ),
      "can't send closure to C function"
  end

  it "errors if sending closured fun pointer to C (2)" do
    assert_error %(
      lib C
        fun foo(callback : ->)
      end

      class Foo
        def bar
        end
      end

      foo = Foo.new
      C.foo(->foo.bar)
      ),
      "can't send closure to C function"
  end

  pending "transforms block to fun literal" do
    assert_type("
      def foo(&block : Int32 ->)
        block.call(1)
      end

      foo do |x|
        x.to_f
      end
      ") { float64 }
  end
end