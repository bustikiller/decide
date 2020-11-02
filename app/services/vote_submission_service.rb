# frozen_string_literal: true

class VoteSubmissionService
  attr_reader :group, :voting, :response

  def initialize(group, voting, response)
    @group = group
    @voting = voting
    @response = response.transform_values { |v| v.is_a?(Hash) ? v : { v => 1 } }
                        .transform_values { |v| v.transform_values(&:to_i) }
  end

  def vote!
    voting.perform_voting_validations!(response)
    verify_group_presence!

    @response = voting.transform_votes(@response, available_votes: available_votes)

    verify_group_already_voted!
    verify_voting_status!
    verify_questions_belong_to_voting!
    verify_options_belong_to_question!

    unless response.size == voting.questions.count
      raise Errors::VotingError, I18n.t('errors.missing_votes_for_question')
    end

    unless response.values.all? { |question_responses| question_responses.values.sum == available_votes }
      raise Errors::VotingError, I18n.t('errors.invalid_number_votes', votes: available_votes)
    end

    ActiveRecord::Base.transaction do
      response.values.inject(:merge).each do |option_id, votes|
        votes.times { Vote.create!(option_id: option_id, group_id: stored_group_id) }
      end
      VoteSubmission.create!(group: group, voting: voting, votes_submitted: available_votes)
    end
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::NotNullViolation
    raise Errors::VotingError, I18n.t('errors.missing_option')
  rescue ActiveRecord::RecordInvalid => e
    raise Errors::VotingError, e.message.split(':').last.strip
  end

  private

  def available_votes
    group.votes_in_body(voting.body)
  end

  def verify_group_presence!
    unless group.present?
      raise Errors::VotingError, 'The group was not provided'
    end
  end

  def verify_group_already_voted!
    if VoteSubmission.where(group: group, voting: voting).any?
      raise Errors::VotingError, I18n.t('errors.already_voted')
    end
  end

  def verify_voting_status!
    unless voting.open?
      raise Errors::VotingError, "Cannot submit votes for a voting in #{voting.status} status"
    end
  end

  def verify_questions_belong_to_voting!
    if Question.where(id: question_ids).where.not('questions.voting_id = ?', voting.id).any?
      raise Errors::VotingError, 'One of the questions does not belong to the voting provided'
    end
  end

  def verify_options_belong_to_question!
    response.map { |k, v| [k, v.keys] }.to_h.each do |question_id, option_ids|
      if Option.where(id: option_ids).where.not(question_id: question_id).any?
        raise Errors::VotingError, 'One of the options does not belong to the question provided'
      end
    end
  end

  def question_ids
    response.keys
  end

  def stored_group_id
    group.id unless voting.secret?
  end
end
