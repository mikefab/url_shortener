class HomeController < ApplicationController

  def index
    if params[:short]
      if u = Url.find_by_short(UrlShortener.clean_short_url(params[:short]))
        redirect_to u.name 
      else
        flash[:notice] = "There is no url for this phrase."
      end
    end
    @short_url = Url.find_or_create_by_name(params[:url]) if params[:url]
  end
end
