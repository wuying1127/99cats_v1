class CatRentalRequest < ActiveRecord::Base
  STATUS_STATES = %w(APPROVED PENDING DENIED)

  validates :cat_id, :start_date, :end_date, :status, presence: true
  validates :status, inclusion: STATUS_STATES

  belongs_to :cat

  after_initialize :assign_pending_status

  def overlapping_requests
    CatRentalRequest
      .where.not(id: self.id)
      .where(cat_id: cat_id)
      .where(<<-SQL, start_date: start_date, end_date: end_date)
        NOT( (start_date > :end_date) OR ( end_date < :start_date) )
      SQL
  end

  def overlapping_approved_requests
    overlapping_requests.where("status = 'APPROVED'")
  end

  def does_not_overlap_approved_request
    return if self.denied?
    unless overlapping_approved_requests.empty?
      errors[:base] <<
        "Request conflicts with existing approve request"
    end
  end

  def overlapping_pending_requests
    overlapping_requests.where("status = 'PENDING'")
  end

  def approve!
    raise "not pending" unless self.status == "PENDING"
    transaction do
      self.status = "APPROVED"
      self.save!
      overlapping_pending_requests.update_all(status: "DENIED")
    end
  end

  def approved?
    self.status = "APPROVED"
  end

  def deny!
    self.status = "DENIED"
    self.save!
  end

  def denied?
    self.status = "DENIED"
  end

  def pending?
    self.status = "PENDING"
  end

  private
  def assign_pending_status
    self.status ||= "PENDING"
  end

end
