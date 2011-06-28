module EventsHelper
  def events_archive_list
    events = Event.select('start_at').for_archive_list
    return nil if events.blank?
    html = '<ul>'
    links = []
    super_old_links = []

    events.each do |e|
      if e.start_at >= Time.now.end_of_year.advance(:years => -3)
        links << e.start_at.strftime('%m/%Y') 
      else
        super_old_links << e.start_at.strftime('01/%Y')
      end
    end
    links.uniq!
    super_old_links.uniq!
    links.each do |l|
      year = l.split('/')[1]
      month = l.split('/')[0]
      count = Event.by_archive(Time.parse(l)).size
      text = t("date.month_names")[month.to_i] + " #{year} (#{count})"      
      html << "<li>"
      html << link_to(text, archive_events_path(:year => year, :month => month))
      html << "</li>"
    end
    super_old_links.each do |l|
      year = l.split('/')[1]
      count = Event.by_year(Time.parse(l)).size
      text = "#{year} (#{count})"
      html << "<li>"
      html << link_to(text, archive_events_path(:year => year))
      html << "</li>"
    end
    html << '</ul>'
    html.html_safe
  end
  
  def to_ics(e)
    url = "#{self.request.protocol}#{self.request.host}:#{self.request.port}/"
    
    event = Icalendar::Event.new
    event.start = e.start_at.strftime("%Y%m%dT%H%M%S")
    event.end = e.end_at.strftime("%Y%m%dT%H%M%S")
    event.summary = e.title
    event.description = e.description.gsub(/<\/?[^>]*>/, "")
    event.location = "#{e.venue_name}, #{e.venue_address}"
    event.klass = 'PUBLIC'
    event.created = e.created_at.strftime("%Y%m%dT%H%M%S")
    event.last_modified = e.updated_at.strftime("%Y%m%dT%H%M%S")
    event.uid = "EVENT-#{e.id}"
    event.url = "#{url}events/#{e.slugs.last.name}"
        
    categories = e.categories.each do |category|
      event.add_category(category.name)
    end
    
    event.add_comment("Price: #{e.ticket_price}") unless e.ticket_price.to_i == 0
    event.add_comment("Ticket link: #{e.ticket_link}") unless e.ticket_link.empty?
    
    event
  end
end