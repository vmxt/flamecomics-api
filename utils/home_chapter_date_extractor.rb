# frozen_string_literal: true

module HomeChapterDateExtractor
  private

  def extract_chapter_date(link)
    date_selectors.each do |selector|
      date = date_containers(link).filter_map { |node| node.at_css(selector)&.text&.strip }.find(&:itself)
      return date unless date.to_s.empty?
    end

    nil
  end

  def date_selectors
    [
      'p[class*="SeriesCard_date"]',
      '[class*="SeriesCard_date"]',
      'p[data-size="xs"][data-line-clamp="true"]'
    ]
  end

  def date_containers(link)
    [link.parent, link.ancestors.first, link.ancestors[1]].compact
  end
end
