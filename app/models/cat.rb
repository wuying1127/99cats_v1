require 'action_view'

class Cat < ActiveRecord::Base
  include ActionView::Helpers::DateHelper

  CAT_COLORS = %w(black white orange brown)

  validates :birth_date, :name, :color, :sex, :description, presence: true
  validates :color, inclusion: CAT_COLORS
  validates :sex, inclusion: %w(M F)

  has_many :rental_requests,
  foreign_key: :cat_id,
  class_name: "CatRentalRequest",
  dependent: :destroy

  def age
    time_ago_in_words(birth_date)
  end

end
