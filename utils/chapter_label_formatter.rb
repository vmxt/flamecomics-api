# frozen_string_literal: true

module ChapterLabelFormatter
  private

  def format_chapter_number(number)
    number.to_s.sub(/\.0+\z/, '')
  end

  def format_chapter_label(chapter)
    number = format_chapter_number(chapter['chapter'])
    title = chapter['title'].to_s.strip

    return "Chapter #{number}" if title.empty?

    "Chapter #{number} - #{title}"
  end

  def chapter_number_from_label(label)
    label.to_s[/Chapter\s+([^\s-]+)/i, 1]
  end

  def chapter_title_from_label(label)
    label.to_s.sub(/\AChapter\s+[^\s-]+\s*-\s*/i, '').sub(/\AChapter\s+[^\s-]+\z/i, '').strip
  end
end
