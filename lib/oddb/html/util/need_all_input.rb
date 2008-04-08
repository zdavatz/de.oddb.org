#!/usr/bin/env ruby
# Html::Util::NeedAllInput -- de.oddb.org -- 08.04.2008 -- hwyss@ywesee.com

module ODDB
  module Html
    module Util
module NeedAllInput
  def user_input(keys, mandatory)
    input = super
    pass1 = input[:pass]
    pass2 = input[:confirm_pass]
    unless(@user || pass1 == pass2)
      err1 = create_error(:e_non_matching_set_pass, :pass, pass1)
      err2 = create_error(:e_non_matching_set_pass, :confirm_pass, pass2)
      @errors.store(:pass, err1)
      @errors.store(:confirm_pass, err2)
    end
    msg = 'e_need_all_input'
    @errors.each { |key, err|
      if(err.message.match(/^e_missing_/))
        @errors.store(key, create_error(msg, key, err.value))
      end
    }
    input
  end
end
    end
  end
end
