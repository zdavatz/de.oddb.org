#!/usr/bin/env ruby
# Export::TestRss -- de.oddb.org -- 10.12.2007 -- hwyss@ywesee.com

$: << File.expand_path('..', File.dirname(__FILE__))
$: << File.expand_path('../../lib', File.dirname(__FILE__))

require 'flexmock'
require 'oddb/export/rss'
require 'oddb/util/code'
require 'stub/model'
require 'test/unit'

module ODDB
  module Export
    module Rss
class TestFeedback < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    ARGV.push ''
    Util::Feedback.instances.clear
    @exporter = Feedback.new
    @f1 = Util::Feedback.new
    @f1.time = Time.now
    @f1.name = "Test User"
    @f1.message = "Test Message"
    @f1.email = "test@email.com"
    @f1.item_good_impression = true
    @f1.save
    @i1 = flexmock('package')
    @i1.should_receive(:code).with(:cid).and_return { 
      Util::Code.new(:cid, 12345, 'DE') } 
    @i1.should_ignore_missing
    @f1.item = @i1
    @f2 = Util::Feedback.new
    @f2.time = Time.now
    @f2.save
    super
  end
  def test_sorted_feedbacks
    assert_equal([@f2, @f1], @exporter.sorted_items)
  end
  def test_rss
    # note: only one feedback should be reported, because @f2.item is nil.
    expected = <<-EOS
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet href=\"http://de.oddb.org/resources/oddb/oddb.css\" type=\"text/css\"?>
<rss version=\"2.0\"
  xmlns:trackback=\"http://madskills.com/public/xml/rss/module/trackback/\">
  <channel>
    <title>Patienten- und \303\204rztefeedback zu Medikamenten</title>
    <link>http://de.oddb.org/de/home/</link>
    <description>Patienten- und \303\204rztefeedback zu Medikamenten im Schweizer Gesundheitsmarkt</description>
    <language>de</language>
    <item>
      <title>Feedback zu  in der Handelsform: </title>
      <link>http://de.oddb.org/de/feedback/pzn/12345/index/1</link>
      <description>&lt;!DOCTYPE HTML PUBLIC &quot;-//W3C//DTD HTML 4.01//EN&quot; &quot;http://www.w3.org/TR/html4/strict.dtd&quot;&gt;&lt;HTML&gt;&lt;HEAD&gt;&lt;TITLE&gt;DE - ODDB.org&lt;/TITLE&gt;&lt;LINK href=&quot;http://de.oddb.org/resources/oddb/oddb.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot;&gt;&lt;/HEAD&gt;&lt;BODY&gt;&lt;DIV&gt;&lt;TABLE cellspacing=&quot;0&quot;&gt;&lt;TR&gt;&lt;TD colspan=&quot;2&quot;&gt;Feedback von Test User, erstellt am: #{@f1.time.strftime("%A, %d. %B %Y")}&lt;/TD&gt;&lt;/TR&gt;&lt;TR&gt;&lt;TD&gt;&lt;LABEL for=&quot;email&quot;&gt;E-Mail&lt;/LABEL&gt;&lt;/TD&gt;&lt;TD&gt;E-Mail wird nicht angezeigt.&lt;/TD&gt;&lt;/TR&gt;&lt;TR&gt;&lt;TD class=&quot;top&quot;&gt;&lt;LABEL for=&quot;message&quot;&gt;Feedback&lt;/LABEL&gt;&lt;/TD&gt;&lt;TD&gt;Test Message&lt;/TD&gt;&lt;/TR&gt;&lt;TR&gt;&lt;TD&gt;&lt;LABEL&gt;Pers\303\266nliche Erfahrung&lt;/LABEL&gt;&lt;/TD&gt;&lt;TD&gt;&lt;DIV class=&quot;square minus&quot;&gt;-&lt;/DIV&gt;&lt;/TD&gt;&lt;/TR&gt;&lt;TR&gt;&lt;TD&gt;&lt;LABEL&gt;Empfehlung&lt;/LABEL&gt;&lt;/TD&gt;&lt;TD&gt;&lt;DIV class=&quot;square minus&quot;&gt;-&lt;/DIV&gt;&lt;/TD&gt;&lt;/TR&gt;&lt;TR&gt;&lt;TD&gt;&lt;LABEL&gt;Pers\303\266nlicher Eindruck&lt;/LABEL&gt;&lt;/TD&gt;&lt;TD&gt;&lt;DIV class=&quot;square plus&quot;&gt;+&lt;/DIV&gt;&lt;/TD&gt;&lt;/TR&gt;&lt;TR&gt;&lt;TD&gt;&lt;LABEL&gt;Wirkung&lt;/LABEL&gt;&lt;/TD&gt;&lt;TD&gt;&lt;DIV class=&quot;square minus&quot;&gt;-&lt;/DIV&gt;&lt;/TD&gt;&lt;/TR&gt;&lt;/TABLE&gt;&lt;/DIV&gt;&lt;DIV&gt;&lt;A href=&quot;http://de.oddb.org/de/feedbacks/pzn/12345&quot; name=&quot;feedback_feed_link&quot;&gt;&lt;/A&gt;&lt;/DIV&gt;&lt;/BODY&gt;&lt;/HTML&gt;</description>
      <author>de.ODDB.org</author>
      <pubDate>#{@f1.time.rfc2822}</pubDate>
      <guid isPermaLink=\"true\">http://de.oddb.org/de/feedback/pzn/12345/index/1</guid>
    </item>
  </channel>
</rss>
    EOS
    # Tue, 11 Dec 2007 13:51:35 +0100
    session = Export::SessionStub.new
    session.language = 'de'
    session.lookandfeel = Html::Util::Lookandfeel.new(session)
    result = @exporter.rss [@f2, @f1], session
    assert_equal expected.strip, result
  end
end
    end
  end
end
