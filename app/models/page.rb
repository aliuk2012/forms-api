require "govuk_forms_markdown"

class Page < ApplicationRecord
  has_paper_trail

  belongs_to :form
  has_many :routing_conditions, class_name: "Condition", foreign_key: "routing_page_id", dependent: :destroy
  has_many :check_conditions, class_name: "Condition", foreign_key: "check_page_id", dependent: :nullify
  has_many :goto_conditions, class_name: "Condition", foreign_key: "goto_page_id", dependent: :nullify
  acts_as_list scope: :form

  ANSWER_TYPES = %w[number address date email national_insurance_number phone_number selection organisation_name text name].freeze

  validates :question_text, presence: true
  validates :question_text, length: { maximum: 250 }

  validates :hint_text, length: { maximum: 500 }

  validates :answer_type, presence: true, inclusion: { in: ANSWER_TYPES }
  validate :guidance_fields_presence
  validates :page_heading, length: { maximum: 250 }
  validate :guidance_markdown_length_and_tags

  def destroy_and_update_form!
    form = self.form
    destroy! && form.update!(question_section_completed: false)
  end

  def save_and_update_form
    return true unless has_changes_to_save?

    save!
    form.update!(question_section_completed: false)
    check_conditions.destroy_all if answer_type_changed_from_selection
    check_conditions.destroy_all if answer_settings_changed_from_only_one_option

    true
  end

  def next_page
    lower_item&.id
  end

  def as_json(options = {})
    options[:except] ||= [:next_page]
    options[:methods] ||= %i[next_page has_routing_errors]
    options[:include] ||= { routing_conditions: { methods: %i[validation_errors has_routing_errors] } }
    super(options)
  end

  def answer_type_changed_from_selection
    answer_type_previously_was&.to_sym == :selection && answer_type&.to_sym != :selection
  end

  def answer_settings_changed_from_only_one_option
    from_only_one_option = ActiveModel::Type::Boolean.new.cast(answer_settings_previously_was.try(:[], "only_one_option"))
    to_multiple_options = !ActiveModel::Type::Boolean.new.cast(answer_settings.try(:[], "only_one_option"))

    from_only_one_option && to_multiple_options
  end

  def has_routing_errors
    routing_conditions.filter(&:has_routing_errors).any?
  end

private

  def guidance_fields_presence
    if page_heading.present? && guidance_markdown.blank?
      errors.add(:guidance_markdown, "must be present when Page Heading is present")
    elsif guidance_markdown.present? && page_heading.blank?
      errors.add(:page_heading, "must be present when Guidance Markdown is present")
    end
  end

  def guidance_markdown_length_and_tags
    return true if guidance_markdown.blank?

    markdown_validation = GovukFormsMarkdown.validate(guidance_markdown)

    return true if markdown_validation[:errors].empty?

    if markdown_validation[:errors].include?(:too_long)
      errors.add(:guidance_markdown, :too_long, count: 4999)
    end

    tag_errors = markdown_validation[:errors].excluding(:too_long)
    if tag_errors.any?
      errors.add(:guidance_markdown, :unsupported_markdown_syntax, message: "can only contain formatting for links, subheadings(##), bulleted listed (*), or numbered lists(1.)")
    end
  end
end
