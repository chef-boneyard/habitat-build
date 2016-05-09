module Habitat
  # Error class for promotion errors
  class PromotionError < StandardError
    def initialize(msg = 'Promotion of package on Depot server failed')
      super
    end
  end

  # Error class for upload errors
  class UploadError < StandardError
    def initialize(msg = 'Upload of artifact to Depot server failed')
      super
    end
  end

  # Error class for download errors
  class DownloadError < StandardError
    def initialize(msg = 'Download of artifact from Depot server failed')
      super
    end
  end
end
