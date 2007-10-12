#!/usr/bin/env ruby
# TestModel -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/model'

module ODDB
  class TestModel < Test::Unit::TestCase
    include FlexMock::TestCase
    class Foo < Model
      multilingual :name
      has_many :difficulties, on_delete(:cascade)
    end
    class Bar < Model
      has_many :not_in_foos
    end
    class Baz < Model
      belongs_to :foo, on_save(:cascade)
    end
    class SelfName < Model
    end
    def setup
      @foo = Foo.new
    end
    def test_multilingual
      assert_respond_to(@foo, :name)
      assert_instance_of(Util::Multilingual, @foo.name)
    end
    def test_has_many
      assert_equal(['@difficulties'], Foo.connectors)
      assert_respond_to(@foo, :difficulties)
      assert_equal([], @foo.difficulties)
      assert_respond_to(@foo, :add_difficulty)
      @foo.add_difficulty('a difficult String')
      assert_equal(['a difficult String'], @foo.difficulties)
      assert_respond_to(@foo, :remove_difficulty)
      @foo.remove_difficulty('a difficult String')
      assert_equal([], @foo.difficulties)
    end
    def test_belongs_to
      baz = Baz.new
      assert_respond_to(baz, :foo)
      assert_respond_to(baz, :foo=)
      assert_nil(baz.foo)
      foo = flexmock('foo')
      foo.should_receive(:add_baz).times(1).with(baz)
      foo.should_receive(:save).times(2)
      baz.foo = foo
      assert_equal(foo, baz.foo)
      baz.foo = foo
      assert_equal(foo, baz.foo)
      other = flexmock('other')
      foo.should_receive(:remove_baz).times(1).with(baz)
      other.should_receive(:add_baz).times(1).with(baz)
      other.should_receive(:save).times(2)
      baz.foo = other
      assert_equal(other, baz.foo)
      other.should_receive(:remove_baz).times(1).with(baz)
      baz.foo = nil
      assert_nil(baz.foo)
    end
    def test_singular
      assert_equal('self_name', SelfName.singular)
    end
    def test_predicates__on_delete__cascade
      diff = flexmock('Difficulty')
      @foo.add_difficulty(diff)
      diff.should_receive(:delete).times(1).and_return { assert(true) }
      @foo.delete
    end
    def test_predicates__on_save__cascade
      baz = Baz.new
      foo = flexmock('foo')
      foo.should_receive(:add_baz)
      foo.should_receive(:save).times(2).and_return { assert(true) }
      baz.foo = foo
      baz.save
    end
  end
end
