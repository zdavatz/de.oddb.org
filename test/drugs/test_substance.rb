#!/usr/bin/env ruby
# Drugs::TestSubstance -- de.oddb.org -- 13.11.2006 -- hwyss@ywesee.com

$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'test/unit'
require 'oddb/drugs/substance'

module ODDB
  module Drugs
    class TestSubstance < Test::Unit::TestCase
      include FlexMock::TestCase
      def setup
        @substance = Substance.new
      end
      def test_group_writer
        group = flexmock('group')
        group.should_receive(:add_substance).times(1).with(@substance)
        group.should_receive(:save).times(2)
        assert_nil(@substance.group)
        @substance.group = group
        assert_equal(group, @substance.group)
        @substance.group = group
        assert_equal(group, @substance.group)
        other = flexmock('other group')
        group.should_receive(:remove_substance).times(1).with(@substance)
        other.should_receive(:add_substance).times(1).with(@substance)
        other.should_receive(:save).times(2)
        @substance.group = other
        assert_equal(other, @substance.group)
        other.should_receive(:remove_substance).times(1).with(@substance)
        @substance.group = nil
        assert_nil(@substance.group)
      end
      def test_merge
        @substance.name.de = 'Original'
        other = Substance.new
        other.name.de = 'Merged'
        agent = flexmock('ActiveAgent')
        other.instance_variable_set('@active_agents', [agent])
        agent.should_receive(:substance=).with(@substance).times(1)
        agent.should_receive(:save).times(1)
        agent.should_ignore_missing
        @substance.merge(other)
        assert_equal 'Original', @substance.name.de
        assert_equal ['Original', 'Merged'], @substance.name.all
      end
    end
  end
end
