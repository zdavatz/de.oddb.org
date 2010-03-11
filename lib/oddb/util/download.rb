module ODDB
  module Util
module Download
  def Download.compressed_download(item)
    file = item.text
    if (data = item.data) && (compression = data[:compression]) \
      && !ODDB.config.download_uncompressed.include?(file)
      file += '.' << compression
    end
    file
  end
  def compressed_download(item)
    Download.compressed_download(item)
  end
end
  end
end
