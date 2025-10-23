module TimeHelper
  def self.time_ago_in_words(from_time, to_time = Time.now)
    return 'Unknown' unless from_time

    distance_in_seconds = (to_time - from_time).to_i.abs

    case distance_in_seconds
    when 0..59
      count = distance_in_seconds
      unit = count == 1 ? 'second' : 'seconds'
      "#{count} #{unit} ago"
    when 60..3599
      count = distance_in_seconds / 60
      unit = count == 1 ? 'minute' : 'minutes'
      count == 1 ? "a #{unit} ago" : "#{count} #{unit} ago"
    when 3600..86_399
      count = distance_in_seconds / 3600
      unit = count == 1 ? 'hour' : 'hours'
      count == 1 ? "an #{unit} ago" : "#{count} #{unit} ago"
    when 86_400..2_592_000
      count = distance_in_seconds / 86_400
      unit = count == 1 ? 'day' : 'days'
      count == 1 ? "a #{unit} ago" : "#{count} #{unit} ago"
    when 2_592_001..31_536_000
      count = distance_in_seconds / 2_592_000
      unit = count == 1 ? 'month' : 'months'
      count == 1 ? "a #{unit} ago" : "#{count} #{unit} ago"
    else
      count = distance_in_seconds / 31_536_000
      unit = count == 1 ? 'year' : 'years'
      count == 1 ? "a #{unit} ago" : "#{count} #{unit} ago"
    end
  end
end
