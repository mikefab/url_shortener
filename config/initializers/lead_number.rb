def get_lead_number
  Rails.cache.clear
  unless Url.last.nil?
    return Url.last.short.match(/^\d+/).to_s.to_i
  else
    return 1
  end
end

Rails.cache.write('lead_number', get_lead_number) if ActiveRecord::Base.connection.tables.include?('urls')