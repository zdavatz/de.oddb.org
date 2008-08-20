#!/usr/bin/env ruby
# Html::View::PayPal::ExportForm -- de.oddb.org -- 28.07.2008 -- hwyss@ywesee.com

module ODDB
  module Html
    module View
module PayPal
  class InvoiceItems < HtmlGrid::List
    COMPONENTS = {
      [0,0]  =>  :quantity,
      [1,0]  =>  :text,
      [2,0]  =>  :price,
    }
    CSS_CLASS = 'invoice items'
    CSS_MAP = {
      [0,0]  =>  'right',
      [1,0]  =>  '',
      [2,0]  =>  'right',
    }
    LEGACY_INTERFACE = false
    OMIT_HEADER = true
    STRIPED_BG = false
    def compose_footer(matrix)
      total_net = [nil, @lookandfeel.lookup(:total_netto), nil, total_netto()]
      vat = [nil, @lookandfeel.lookup(:vat), nil, vat()]
      total = [nil, @lookandfeel.lookup(:total_brutto), nil, total_brutto()]
      @grid.add(total_net, *matrix)
      @grid.set_row_attributes({'class' => 'bg'}, matrix.at(1))
      @grid.add_style('right', *resolve_offset(matrix, [2,0]))
      matrix = resolve_offset(matrix, [0,1])
      @grid.add(vat, *matrix)
      @grid.set_row_attributes({'class' => 'bg'}, matrix.at(1))
      @grid.add_style('right', *resolve_offset(matrix, [2,0]))
      matrix = resolve_offset(matrix, [0,1])
      @grid.add(total, *matrix)
      @grid.set_row_attributes({'class' => 'bg'}, matrix.at(1))
      @grid.add_style('right total', *resolve_offset(matrix, [2,0]))
    end
    def text(model)
      model.text
    end
    def format_price(price, currency=nil)
      @lookandfeel.format_price(price.to_f * 100.0, currency)
    end
    def price(model)
      format_price(model.total_netto)
    end
    def quantity(model)
      model.quantity.to_i.to_s << ' x'
    end
    def total_brutto
      format_price(@model.inject(0) { |inj, item|
        inj + item.total_brutto
      }, 'EUR')
    end
    def total_netto
      format_price @model.inject(0) { |inj, item|
        inj + item.total_netto
      }
    end
    def vat
      format_price @model.inject(0) { |inj, item|
        inj + item.vat
      }
    end
  end
  class RegisterForm < HtmlGrid::Form
    include HtmlGrid::ErrorMessage
    COMPONENTS = {
      [0,0]  =>  :email,
      [0,1]  =>  :pass,
      [3,1]  =>  :confirm_pass,
      [0,2]  =>  :salutation,
      [0,3]  =>  :name_last,
      [0,4]  =>  :name_first,
      [1,5]  =>  :submit,
    }
    CSS_CLASS = 'invoice'
    EVENT = :checkout
    LABELS = true
    LEGACY_INTERFACE = false
    SYMBOL_MAP = {
      :salutation   =>  HtmlGrid::Select,
      :pass         =>  HtmlGrid::Pass,
      :confirm_pass =>  HtmlGrid::Pass,
    }
    def init
      @model = @session.user
      super
      error_message
    end
    def email(model, session=@session)
      input = HtmlGrid::InputText.new(:email, model, @session, self)
      url = @lookandfeel._event_url(:ajax_autofill, {:email => nil})
      if(@session.logged_in?)
        input.set_attribute('disabled', true)
      else
        input.set_attribute('onChange', "autofill(this.form, 'email', '#{url}');")
      end
      input
    end
  end
end
    end
  end
end
