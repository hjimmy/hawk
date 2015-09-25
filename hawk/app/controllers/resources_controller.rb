# Copyright (c) 2009-2015 Tim Serong <tserong@suse.com>
# See COPYING for license.

class ResourcesController < ApplicationController
  before_filter :login_required
  before_filter :set_title
  before_filter :set_cib

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: Resource.all.reject { |resource|
          resource.object_type == "template"
        }.to_json
      end
    end
  end

  def status
    result = [].tap do |result|
      selected = []

      Resource.all.each do |resource|
        case resource.object_type
        when "group"
          resource.children.map! do |child|
            r = Resource.find(child)

            selected.push r.id
            r
          end

          result.push resource
        when "clone"
        when "master"
          r = Resource.find(resource.child)

          selected.push r.id
          resource.child = r

          result.push resource
        when "tag"
          resource.refs.map! do |child|
            Resource.find(child)
          end

          result.push resource
        end
      end

      result.push Primitive.all.reject { |resource|
        selected.include? resource.id
      }
    end.flatten

    respond_to do |format|
      format.json do
        render json: result.to_json
      end
    end
  end

  def types
    respond_to do |format|
      format.html
    end
  end

  def show
    @resource = Resource.find params[:id]

    respond_to do |format|
      format.html
    end
  end

  protected

  def set_title
    @title = _("Resources")
  end

  def set_cib
    @cib = current_cib
  end

  def default_base_layout
    if ["index", "types"].include? params[:action]
      "withrightbar"
    else
      if params[:action] == "show"
        "modal"
      else
        super
      end
    end
  end
end
