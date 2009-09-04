require 'oddb/config'

module ODDB
  require File.join('oddb', 'persistence', @config.persistence)
  persistence = nil
  case @config.persistence
  when 'odba'
    DRb.install_id_conv ODBA::DRbIdConv.new
    @persistence = ODDB::Persistence::ODBA
  when 'og'
    DRb.install_id_conv DRb::TimerIdConv.new
    Og.setup({
      :name     => @config.db_name,
      :user     => @config.db_user,
      :password => @config.db_auth,
      :store    => @config.db_backend,
      :evolve_schema => true,
      :evolve_schema_cautious => false,
    })
    @persistence = ODDB::Persistence::Og
  end
end
