# encoding: utf-8

class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Create different versions of avatar
  # use thumb for larger display
  version :thumb do
    process :resize_to_fill => [150, 150]
  end

  # use tiny for user attribution (e.g., annotations)
  version :tiny do
    process :resize_to_fill => [32, 32]
  end

  # White list of extensions allowed to be uploaded
  def extension_white_list
    %w(jpg jpeg gif png)
  end

end
