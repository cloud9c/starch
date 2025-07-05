class EmailSender < ApplicationRecord
  has_many :documents, as: :source, dependent: :destroy
  after_create :schedule_initial_update

  def update_metadata
    domain = email_address.split("@").last
    update(icon: FormatUtils.find_icon(domain))
  end

  private
    def schedule_initial_update
      UpdateEmailSenderJob.perform_now(id)
    end
end
