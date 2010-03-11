require 'oddb/util/download'

module ODDB
  module Html
    module State
      module PayPal
module Download
  include ODDB::Util::Download
  def collect
    if(@session.is_crawler?)
      trigger :home
    else
      invoice = Business::Invoice.find_by_id(@session.user_input(:invoice))
      state = PayPal::Collect.new(@session, invoice)
      # since the permissions of the current User may have changed, we
      # need to reconsider his viral modules
      if((user = @session.user).is_a?(Util::KnownUser))
        reconsider_permissions(user)
      end
      if invoice
        downloads = invoice.items.select do |itm| itm.type == :download end
        file, item = nil
        if file = @session.user_input(:file)
          uncompressed = if ODDB.config.download_uncompressed.include?(file)
                           file
                         else
                           File.basename file, File.extname(file)
                         end
          item = invoice.items.find do |itm| itm.text == uncompressed end
        end
        if item || downloads.size <= 1
          ## just pass through to the download/desired_state directly.
          item ||= invoice.items.first
          case item.type
          when :export, :download
            if @session.allowed?('download', "#{ODDB.config.auth_domain}.#{item.text}") \
              || (invoice.status == 'completed' && !item.expired?)
              extend State::Drugs::Events
              state = _download file || compressed_download(item)
            else
              ## wait for ipn
            end
          else
            if(@session.allowed?('view', ODDB.config.auth_domain))
              if(des = @session.desired_state)
                state = des
              else
                state.extend Drugs::Events
              end
            end
          end
        end
      end
      state
    end
  end
end
      end
    end
  end
end
