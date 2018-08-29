# Section class
class Section < ApplicationRecord
  belongs_to :chapter
  has_many :section_tag_joins
  has_many :tags, through: :section_tag_joins
  has_many :lesson_section_joins
  has_many :lessons, through: :lesson_section_joins
  validates :title, presence: true
  validates :number, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 999 },
                     uniqueness: { scope: :chapter_id,
                                   message: 'section already exists' }
  validate :valid_lessons?
  validate :valid_tags?

  def lecture
    return unless chapter.present?
    chapter.lecture
  end

  def shown_number
    return '§' + number.to_s unless number_alt.present?
    '§' + number_alt
  end

  def to_label
    shown_number + '. ' + title
  end

  private

  def valid_lessons?
    return unless chapter.present? && lessons.present?
    return true if lessons.map(&:lecture_id).uniq == [lecture.id]
    errors.add(:base, 'The lessons you selected do not belong to the lecture ' \
                      'that is associated to to this section.')
    false
  end

  def valid_tags?
    return unless chapter.present? && tags.present?
    return true if (tags.map(&:id) - lecture.tags.pluck(:id)).empty?
    errors.add(:base, 'The tags you selected are not activated for the ' \
                      'lecture that is associated to to this section.')
    false
  end
end
