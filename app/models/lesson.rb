# Lesson class
class Lesson < ApplicationRecord
  belongs_to :lecture
  has_many :lesson_tag_joins
  has_many :tags, through: :lesson_tag_joins
  has_many :lesson_section_joins
  has_many :sections, through: :lesson_section_joins
  has_many :media, as: :teachable
  has_many :editable_user_joins, as: :editable
  validates :date, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 1,
                                     less_than_or_equal_to: 999 },
                     uniqueness: { scope: :lecture_id,
                                   message: 'lesson already exists' }
  validate :valid_date?
  validate :valid_date_for_term?

  def self.select_by_date
    Lesson.all.to_a.sort_by(&:date).map { |l| [l.date, l.id] }
  end

  def term
    return unless lecture.present?
    lecture.term
  end

  def course
    return unless lecture.present?
    lecture.course
  end

  def date_de
    date.day.to_s + '.' + date.month.to_s + '.' + date.year.to_s
  end

  def to_label
    'Nr. ' + number.to_s + ', ' + date_de.to_s
  end

  def title
    return 'Sitzung #' + id.to_s unless number.present? && date.present?
    'Sitzung ' + number.to_s + ', ' + date_de.to_s
  end

  def section_titles
    sections.map(&:title).join(', ')
  end

  def description
    { general: lecture.to_label, specific: title }
  end

  def lesson
    self
  end

  private

  def valid_date_for_term?
    return unless date.present? && term.present?
    return unless valid_date?
    return true if date.between?(term.begin_date, term.end_date)
    errors.add(:date, 'not a valid date for this term')
    false
  end

  def valid_date?
    return unless date.present?
    return true if date.is_a?(Date)
    errors.add(:date, 'not a valid date')
    false
  end
end
