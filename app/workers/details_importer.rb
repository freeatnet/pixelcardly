class DetailsImporter
  include Sidekiq::Worker

  def perform(photo_id)
    begin
      hashie_photo = $pixels_api.photo(photo_id, {comments: 0, image_size: [2, 3, 440, 600, 4], tags: 1}).photo
      #puts "hashie_photo.location: #{hashie_photo.inspect}"
      return unless hashie_photo.latitude.present? and hashie_photo.longitude.present?
      puts "Importing photo #{hashie_photo.id}"
      photo = Photo.import!(hashie_photo)
      puts "Photo #{hashie_photo.id} imported as #{photo._id}"
    rescue PixelsApi::NotFound, PixelsApi::Unauthorized => e
      puts "#{e.to_s} for #{photo_id}"
    end
  end
end