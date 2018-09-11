class Item < ApplicationRecord
  include ApplicationHelper
  belongs_to :section, optional: true
  belongs_to :medium, optional: true
  has_many :referrals, dependent: :destroy
  has_many :referring_media, through: :referrals, source: :medium
  serialize :start_time, TimeStamp

  validates :sort, inclusion: { in: ['remark', 'theorem', 'lemma', 'definition',
                                     'annotation', 'example', 'section',
                                     'self', 'link', 'corollary'],
                                message: 'Unzulässiger Typ' }
  validates :link, http_url: true, if: :proper_link?
  validates :description,
            presence: { message: 'Beschreibung muss vorhanden sein.' },
            if: :link?
  validate :valid_start_time
  validate :start_time_not_too_late
  validate :no_duplicate_start_time
  validate :nonempty_link_or_explanation

  def end_time
    return unless video?
    return TimeStamp.new(total_seconds: medium.video_duration) if next_item.nil?
    TimeStamp.new(total_seconds: next_item.start_time.total_seconds - 0.001)
  end

  def vtt_time_span
    start_time.vtt_string + ' --> ' + end_time.vtt_string + "\n"
  end

  def short_reference
    return math_reference if math_items.include?(sort)
    toc_reference
  end

  def long_reference
    unless sort.in?(['self', 'link'])
      if section.present?
        return medium.teachable.lecture.title_for_viewers +
               ', ' + short_reference
      end
      return medium.title_for_viewers + ', ' + short_reference
    end
    short_reference
  end

  def short_description
    return section.title if sort == 'section' && section.present?
    return medium.title_for_viewers if sort == 'self'
    description
  end

  def local_reference
    unless sort.in?(['self','link'])
      return short_reference + ' ' + description.to_s unless sort == 'section'
      return short_reference + ' ' + description if description.present?
      return short_reference + ' ' + section.title if section.present?
      return short_reference
    end
    non_math_reference
  end

  def local?(referring_medium)
    return false unless section.present?
    self.in?(referring_medium.teachable.lecture.items)
  end

  def global_reference
    unless sort.in?(['self', 'link'])
      if section.present?
        return medium.teachable.lecture.title_for_viewers +
               ', ' + local_reference
      end
      return medium.title_for_viewers + ', ' + local_reference
    end
    non_math_reference
  end

  def vtt_text
    return description if sort == 'link'
    short_description
  end

  def vtt_reference
    short_reference + ': ' + short_description + "\n\n"
  end

  def vtt_meta_reference(referring_medium)
    return 'externe Referenz:' if sort == 'link'
    ref = local?(referring_medium) ? short_reference : long_reference
    'Verweis auf ' + ref + ':'
  end

  def background
    return '#0c0;' if ['remark', 'theorem', 'lemma', 'corollary'].include?(sort)
    return '#1ad1ff;' if ['definition', 'annotation', 'example'].include?(sort)
    return 'lightgray;' if sort == 'link' || sort == 'self'
    ''
  end

  def video_link
    return unless video?
    return video_link_untimed if sort == 'self'
    video_link_timed
  end

  def manuscript_link
    return unless manuscript?
    link = medium.manuscript[:original].url(host: host)
    link += '#page=' + page.to_s if page.present?
    link
  end

  def self.internal_sorts
    [['Definition', 'definition'], ['Bemerkung', 'remark'], ['Lemma', 'lemma'],
     ['Satz', 'theorem'], ['Beispiel', 'example'], ['Anmerkung', 'annotation'],
     ['Folgerung', 'corollary'], ['Abschnitt', 'section']]
  end

  def self.list
    Item.all.select { |i| i.medium.present? || i.sort == 'link' }
        .map { |i| [i.short_reference + ' ' + i.short_description, i.id] }
  end

  def video?
    medium.present? && medium.video.present?
  end

  def manuscript?
    medium.present? && medium.manuscript.present?
  end

  def link?
    sort == 'link'
  end

  private

  def math_items
    ['remark', 'theorem', 'lemma', 'definition', 'annotation', 'example',
     'corollary']
  end

  def other_items
    ['section', 'self', 'link']
  end

  def proper_link?
    sort == 'link' && link.present?
  end

  def next_item
    medium.proper_items_by_time.find do |i|
      i.start_time.total_seconds > start_time.total_seconds
    end
  end

  def sort_long
    hash = { 'definition' => 'Def.', 'theorem' => 'Satz', 'remark' => 'Bem.',
             'lemma' => 'Lemma', 'annotation' => 'Anm.', 'example' => 'Bsp.',
             'corollary' => 'Folgerung'}
    hash[sort]
  end

  def math_item_number
    if section.present? && sort != 'annotation'
      return section.reference_number.to_s + '.' + (ref_number || '')
    end
    ref_number.to_s
  end

  def math_reference
    sort_long + ' ' + math_item_number
  end

  def special_reference
    return 'Medium' if sort == 'self'
    'extern'
  end

  def section_reference
    return section.displayed_number.to_s if section.present?
    '§' + (ref_number || '')
  end

  def toc_reference
    return section_reference if sort == 'section'
    special_reference
  end

  def video_link_untimed
    Rails.application.routes.url_helpers.play_medium_path(medium.id)
  end

  def video_link_timed
    Rails.application.routes.url_helpers
         .play_medium_path(medium.id, time: start_time.total_seconds)
  end

  def valid_start_time
    return true if start_time.nil?
    return true if start_time.valid?
    errors.add(:start_time, 'Ungültiges Zeitformat.')
    false
  end

  def start_time_not_required
    medium.nil? || sort == 'self' || !start_time.valid?
  end

  def start_time_not_too_late
    return true if start_time_not_required
    return true if start_time.total_seconds <= medium.video.metadata['duration']
    errors.add(:start_time, 'Startzeit darf nicht größer sein als Videolänge.')
    false
  end

  def start_times_without
    (medium.proper_items - [self]).map do |i|
      [i.start_time.floor_seconds, i.start_time.milliseconds]
    end
  end

  def no_duplicate_start_time
    return true if start_time_not_required
    if start_times_without.include?([start_time.floor_seconds,
                                     start_time.milliseconds])
      errors.add(:start_time,
                 'Für diese Startzeit gibt es bereits einen Eintrag.')
      false
    end
    true
  end

  def nonempty_link_or_explanation
    return true if sort != 'link'
    return true if link.present?
    return true if explanation.present?
    errors.add(:link,
               'Link und Erläuterung können nicht gleichzeitig leer sein.')
    errors.add(:explanation,
               'Link und Erläuterung können nicht gleichzeitig leer sein.')
  end

  def non_math_reference
    return medium.title_for_viewers if sort == 'self'
    'extern ' + description.to_s if sort == 'link'
  end
end
