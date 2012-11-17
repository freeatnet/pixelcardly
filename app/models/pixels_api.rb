class PixelsApi
  include HTTParty
  base_uri 'https://api.500px.com/v1'
  format :json

  #debug_output $stderr

  class << self
    # Totally borrowed this from Klout API gem
    # Get the Base URI.
    def base_uri; @@base_uri end

    def get(*args); handle_response super end
    def post(*args); handle_response super end
    def put(*args); handle_response super end
    def delete(*args); handle_response super end

    def handle_response(response) # :nodoc:
      case response.code
      when 400
        raise BadRequest.new response.parsed_response
      when 401
        raise Unauthorized.new
      when 404
        raise NotFound.new
      when 400...500
        raise ClientError.new response.parsed_response
      when 500...600
        raise ServerError.new
      else
        Hashie::Mash.new(response)
      end
    end
  end

  class ApiError < StandardError
    attr_reader :data
    def initialize(data)
      @data = Hashie::Mash.new(data)
      super "The 500px API responded with the following error - #{data}"
    end
  end

  class ClientError < StandardError; end
  class ServerError < StandardError; end
  class BadRequest < ApiError; end
  class Unauthorized < StandardError; end
  class NotFound < ClientError; end
  class Unavailable < StandardError; end

  def initialize(consumer_key)
    @consumer_key = consumer_key
  end

  def user(user_id_or_username, query_opts={})
    if user_id_or_username.numeric?
      query_opts.merge!({id: user_id_or_username})
    else
      query_opts.merge!({username: user_id_or_username})
    end
    self.class.get("/users/show", query: query_opts.merge({consumer_key: @consumer_key}))
  end

  def photo(photo_id, query_opts={})
    self.class.get("/photos/#{photo_id}", query: query_opts.merge({consumer_key: @consumer_key}))
  end

  def photos_by_feature(feature, query_opts={})
    self.class.get("/photos", query: query_opts.merge({feature: feature, consumer_key: @consumer_key}))
  end

  def photos_by_tag(tag, query_opts={})
    self.class.get("/photos/search", query: query_opts.merge({tag: tag, consumer_key: @consumer_key}))
  end
end