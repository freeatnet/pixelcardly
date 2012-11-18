class PhotosController < ApplicationController

  def index
    # Expects parameters
    # latitude Integer/Float [-180.0, 180.0)
    # longitude Integer/Float [-180.0, 180.0)
    # distance Integer ???
    # tag String tag to search by

    respond_to do |f|
      f.json { render status: 400, json: { status: 400, message: "Missing latitude or longitude parameter."}}
    end and return if params[:latitude].blank? or params[:longitude].blank?

    respond_to do |f|
      f.json { render status: 400, json: { status: 400, message: "Latitude or longitude parameter is not a number."}}
    end and return unless params[:latitude].numeric? or params[:longitude].numeric?

    respond_to do |f|
      f.json { render status: 400, json: { status: 400, message: "Invalid (non-numeric) distance parameter."}}
    end and return if params[:distance].present? and not params[:distance].numeric?

    respond_to do |f|
      f.json { render status: 400, json: { status: 400, message: "Missing tag parameter."}}
    end and return if params[:tag].blank?

    rpp = 50

    params[:distance] = 50 unless params[:distance].present?
    params[:page] = 1 unless params[:page].present? and params[:page].numeric?

    latlong_pair = [params[:latitude].to_f, params[:longitude].to_f]
    near_parameter = {"$near" => latlong_pair, "$maxDistance" => params[:distance].to_f}

    scope_count = Photo.where({location: near_parameter, tags: params[:tag]}).count

    respond_to do |f|
      f.json { render status: 400, json: {status: 400, message: "Page out of bounds"}}
    end and return if params[:page].to_i > 1 and rpp * params[:page].to_i > scope_count

    offset = (params[:page].to_i - 1) * rpp

    photos = Photo.where({location: near_parameter, tags: params[:tag]}).offset(offset).limit(rpp)

    respond_to do |f|
      f.html { render locals: {photos: photos} }
      f.json { render status: 200, json: { 
        total_items: scope_count,
        total_pages: (scope_count / rpp),
        current_page: params[:page],
        photos: photos.collect {|photo| p = photo.attributes; p[:author] = photo.author.attributes; p }
      }
    }
    end
  end

  def tags
    map = %Q{
      function() {
          if (!this.tags) {
              return;
          }

          for (index in this.tags) {
              emit(this.tags[index], 1);
          }
      }
    }

    reduce = %Q{
      function(previous, current) {
          var count = 0;

          for (index in current) {
              count += current[index];
          }

          return count;
      }
    }

    latlong_pair = [params[:latitude].to_f, params[:longitude].to_f]
    near_parameter = {"$near" => latlong_pair, "$maxDistance" => params[:distance].to_f}

    total_number_of_photos = Photo.count

    if Mongoid.default_session[:tags_map].find().count == 0
      tags_map = Photo.map_reduce(map, reduce).out(replace: "tags_map")
    else 
      tags_map = Mongoid.default_session[:tags_map].find().to_a
    end

    number_of_taggings = tags_map.collect {|t| t["value"] }.sum
    total_number_of_tags = tags_map.count

    location_tags_map = Photo.where({location: near_parameter}).map_reduce(map, reduce).out(inline: true)
    number_of_location_taggings = location_tags_map.collect {|t| t["value"] }.sum
    number_of_location_tags = location_tags_map.count

    location_tags_to_tf = location_tags_map.collect do |t|
      term_frequency = (t["value"] / (number_of_location_taggings * 1.00))
      inverse_term_frequency = number_of_taggings / (tags_map.select {|_t| _t["_id"] == t["_id"]}.first["value"] * 1.0)

      {_id: t["_id"], value: (term_frequency / (inverse_term_frequency * 1.0)) * 100.0 }
    end

    respond_to do |f|
      f.json { render json: location_tags_to_tf.sort_by {|t| -1 * t[:value] }.take(20).collect {|t| t[:_id]} }
    end
  end

end