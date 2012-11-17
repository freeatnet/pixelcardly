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
    end and return if rpp * params[:page].to_i > scope_count

    offset = (params[:page].to_i - 1) * rpp

    photos = Photo.where({location: near_parameter, tags: params[:tag]}).offset(offset).limit(rpp)

    respond_to do |f|
      f.html { render locals: {photos: photos} }
      f.json { render status: 200, json: { 
        total_items: scope_count,
        total_pages: (scope_count / rpp),
        current_page: params[:page],
        photos: photos
      }
    }
    end
  end

end