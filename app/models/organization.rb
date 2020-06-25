# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :votings, dependent: :destroy
  has_many :groups, through: :users

  validates_presence_of :name
  validates_uniqueness_of :name
end
