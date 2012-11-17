class Photo
  include Mongoid::Document

  field :name, type: String, default: ""
  field :description, type: String, default: ""
  field :license, type: Integer, default: 0
  field :tags, type: Array
  field :location, type: Array

  field :image_urls, type: Hash

  attr_accessible :_id, :name, :description, :license, :tags, :location, :image_urls

  belongs_to :author, class_name: "PhotoAuthor"

  index({ location: "2d", tags: 1 })

  def self.import!(hashie_photo)
    find_or_create_by(_id: hashie_photo.id) do |photo|
      photo.name = hashie_photo.name
      photo.description = hashie_photo.description
      photo.license = hashie_photo.license_type

      photo.tags = hashie_photo.tags if hashie_photo.tags.present?

      if hashie_photo.latitude.present? and hashie_photo.longitude.present?
        photo.location = [hashie_photo.latitude, hashie_photo.longitude]
      end

      author = PhotoAuthor.import!(hashie_photo.user)
      photo.author = author

      photo.image_urls = hashie_photo.images.inject({}) do |hash, element|
        hash[element[:size]] = element.url # Why [:size]? Because .size would return the length of the object (since it is Enumerable!)
        hash
      end
    end
  end
end
