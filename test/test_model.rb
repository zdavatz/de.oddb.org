#!/usr/bin/env ruby
# TestModel -- de.oddb.org -- 12.09.2006 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'oddb/model'

module ODDB
  class TestModel < Test::Unit::TestCase
    class Foo < Model
      multilingual :name
      has_many :difficulties
    end
    class Bar < Model
      has_many :not_in_foos
    end
    def setup
      @foo = Foo.new
    end
    def test_multilingual
      assert_respond_to(@foo, :name)
      assert_instance_of(Util::Multilingual, @foo.name)
    end
    def test_has_many
      assert_equal([:difficulties], Foo.connectors)
      assert_respond_to(@foo, :difficulties)
      assert_equal([], @foo.difficulties)
      assert_respond_to(@foo, :add_difficulty)
      @foo.add_difficulty('a difficult String')
      assert_equal(['a difficult String'], @foo.difficulties)
      assert_respond_to(@foo, :remove_difficulty)
      @foo.remove_difficulty('a difficult String')
      assert_equal([], @foo.difficulties)
    end
  end
end
