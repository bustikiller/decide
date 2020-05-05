# frozen_string_literal: true

class MultiselectVoting < Voting
  validates_numericality_of :max_options, only_integer: true, allow_nil: true, greater_than_or_equal_to: 0

  after_save :handle_options

  attr_accessor :options

  def self.model_name
    Voting.model_name
  end

  def transform_votes(votes, options = {})
    votes.transform_values do |question_response|
      if question_response.values.first.positive?
        question_response
      else
        { Option.find(question_response.keys.first).question.options.no.first.id => options[:available_votes] }
      end
    end
  end

  private

  def handle_options
    all_questions = options.split
    questions_already_present = questions.pluck(:title)
    questions_to_delete = questions_already_present - all_questions
    questions_to_create = all_questions - questions_already_present

    questions_to_create.each do |question|
      q = questions.create!(title: question)
      %w[Yes No].each { |title| q.options.create!(title: title) }
    end

    questions.where(title: questions_to_delete).destroy_all
  end
end
