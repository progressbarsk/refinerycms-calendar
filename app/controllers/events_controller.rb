class EventsController < ApplicationController

  before_filter :find_all_events
  before_filter :find_page
  before_filter :find_categories

  helper [:events, :event_categories]

  #  layout proc{ |c| c.request.xhr? ? false : "application" }

  def index
    # you can use meta fields from your model instead (e.g. browser_title)
    # by swapping @page for @event in the line below:
    present(@page)
  end

  def show
    @event = Event.find(params[:id])
    if canonical?
      if @event.slugs.any?
        #        @canonical = url_for(:id => @event.slugs.where(:locale => :sk).first.name, :locale => ::Refinery::I18n.default_frontend_locale)
        @canonical = url_for(:id => @event.slugs.first.name, :locale => ::Refinery::I18n.default_frontend_locale)
      else
        @canonical = url_for(:locale => ::Refinery::I18n.default_frontend_locale) if canonical?
      end
    end
    # you can use meta fields from your model instead (e.g. browser_title)
    # by swapping @page for @event in the line below:
    present(@page)
  end

  def archive
    if params[:month].present?
      date = "#{params[:month]}/#{params[:year]}"
      @archive_date = Time.parse(date)
      @date_title = @archive_date.strftime('%B %Y')
      @events = Event.by_archive(@archive_date).paginate({
          :page => params[:page],
          :per_page => RefinerySetting.find_or_set(:events_per_page, 10)
        })
    else
      date = "01/#{params[:year]}"
      @archive_date = Time.parse(date)
      @date_title = @archive_date.strftime('%Y')
      @events = Event.by_year(@archive_date).paginate({
          :page => params[:page],
          :per_page => RefinerySetting.find_or_set(:events_per_page, 10)
        })
    end

    render :json => @events if request.xhr?
  end

  protected

  def find_all_events
    upcoming = Event.upcoming.not_featured
    current = Event.current.not_featured
    @events = (upcoming | current).sort { |a,b| a.start_at <=> b.start_at }

    featured_upcoming = Event.upcoming.featured
    featured_current = Event.current.featured
    @featured_events = (featured_upcoming | featured_current).sort { |a,b| a.start_at <=> b.start_at }

    @other_events = Event.live.limit(5)
  end

  def find_page
    @page = Page.find_by_link_url("/events")
  end

  def find_categories
    @event_categories = EventCategory.all
  end

  def canonical?
    canonical = (::Refinery.i18n_enabled? &&
                ::Refinery::I18n.default_frontend_locale != ::Refinery::I18n.current_frontend_locale) ||
                (@event.slugs.any? && @event.slugs.first.name != params[:id])
    canonical
  end

end
