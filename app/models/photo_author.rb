class PhotoAuthor
  include Mongoid::Document

  field :username, type: String
  field :fullname, type: String
  field :userpic_url, type: String

  attr_accessible :_id, :username, :fullname, :userpic_url

  has_many :photos

  def self.import!(hashie_author)
    find_or_create_by(_id: hashie_author.id) do |author|
      author.username = hashie_author.username
      author.fullname = hashie_author.fullname
      author.userpic_url = hashie_author.userpic_url
    end
  end
end
