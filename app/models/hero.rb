class Hero < ApplicationRecord
  has_many :chosen_heros
  has_many :matches, through: :chosen_heros
end