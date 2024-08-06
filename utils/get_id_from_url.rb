def get_id_from_url(str, for_series = false)
  if for_series
    match = str.match(%r{/series/(?:\d+-)?(.+)/})
    match ? match[1].tr('/', '') : nil
  else
    match = str.match(%r{/([^/]+)/$})
    match ? match[1].tr('-', '-') : nil
  end
end
