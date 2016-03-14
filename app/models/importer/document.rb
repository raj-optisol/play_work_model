require 'uri'

class Importer
  class Document
    attr_reader :source_url, :kind, :upload_response

    def initialize(source_url, kind)
      @source_url = source_url
      @kind       = kind
    end

    def retrive
      upload!
      self
    end

    def filename
      @filename ||= File.split(source_uri.path).last
    end

    def to_kyck_document_params
      {
        title: "#{filename}-#{kind}",
        status: :not_reviewed,
        kind: kind,
        file_name: upload_response["file_name"],
        url: upload_response["url"]
      }
    end

    def to_kyck_avatar_params
      {
        avatar: upload_response["public_id"],
        avatar_uri: upload_response["secure_url"],
        avatar_version: upload_response["version"]
      }
    end

    private

    def source_uri
      @source_uri ||= URI(source_url)
    end

    def upload!
      @upload_response = Cloudinary::Uploader.upload(source_url, format: 'jpg')
    end
  end
end

