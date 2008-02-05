#!/usr/bin/env ruby
# Util::Ydim -- de.oddb.org -- 30.01.2008 -- hwyss@ywesee.com

require 'ydim/config'
require 'ydim/client'
require 'oddb/config'
require 'oddb/util/yus'
require 'openssl'

module ODDB
  module Util
module Ydim
  DATE_FMT = "%d.%m.%Y"
  SALUTATIONS = {
    'salutation_m'  =>  'Herr',  
    'salutation_f'  =>  'Frau',  
  }
  def Ydim.connect(&block)
    config = YDIM::Client::CONFIG
    server = DRbObject.new(nil, config.server_url)
    client = YDIM::Client.new(config)
    key = OpenSSL::PKey::DSA.new(File.read(config.private_key))
    client.login(server, key)
    block.call(client)
  ensure
    client.logout if(client)
  end
  def Ydim.create_debitor(email)
    connect { |client|
      keys = [ :salutation, :name_last, :name_first ]
      info = Util::Yus.get_preferences(email, keys)
      debitor = client.create_debitor
      debitor.salutation = SALUTATIONS[info[:salutation]]
      debitor.contact_firstname = info[:name_first]
      debitor.contact = info[:name_last]
      debitor.debitor_type = 'dt_info'
      debitor.email = email
      debitor.save
      debitor
    }
  end
  def Ydim.debitor_id(email)
    if(id = Util::Yus.get_preference(email, :ydim_id))
      id
    elsif(debitor = identify_debitor(email))
      debitor.unique_id
    else
      create_debitor(email).unique_id
    end
  end
  def Ydim.identify_debitor(email)
    connect { |client|
      client.search_debitors(email).first
    }
  end
  def Ydim.inject(invoice, opts = {:payment_received => false})
    if(id = invoice.ydim_id)
      Ydim.connect { |client| client.invoice(id) }
    elsif(email = invoice.yus_name)
      ydim_inv = inject_from_items(invoice_date(invoice), email, invoice.items,
                                  invoice.currency || 'EUR')
      ydim_inv.payment_received = opts[:payment_received]
      ydim_inv.save
      invoice.ydim_id = ydim_inv.unique_id
      invoice.save
      ydim_inv
    end
  end
  def Ydim.inject_from_items(date, email, items, currency='EUR')
    connect { |client|
      debitor_id = debitor_id(email)
      Util::Yus.set_preference(email, :ydim_id, debitor_id)
      ydim_inv = client.create_invoice(debitor_id)
      ydim_inv.description = invoice_description(items)
      ydim_inv.date = date
      ydim_inv.currency = currency
      ydim_inv.payment_period = ODDB.config.payment_period
      item_data = sort_items(items).collect { |item| 
        if(sprintf('%1.2f', item.quantity) == "0.00")
          ydim_inv.precision = 3
        end
        item.ydim_data 
      }
      client.add_items(ydim_inv.unique_id, item_data)
      ydim_inv
    }
  end
  def Ydim.invoice_date(invoice)
    Date.new(invoice.time.year, invoice.time.month, invoice.time.day)
  end
  def Ydim.invoice_description(items)
    types = []
    items.each { |item| types.push(item.type) }
    main = items.first
    if(types.include?(:poweruser))
      exp = main.expiry_time || main.time + (24 * 60 *60)
      sprintf("PowerUser %s %s - %s", ODDB.config.server_name, 
              main.time.strftime(DATE_FMT), exp.strftime(DATE_FMT))
    else
      sprintf("%s %s", ODDB.config.server_name, main.time.strftime(DATE_FMT))
    end
  end
  def Ydim.sort_items(items)
    items.sort_by { |item| 
      [item.time.to_i / (24 * 60 * 60), item.text, item.type.to_s]
    }
  end
end
  end
end
