module User::Emailable
  extend ActiveSupport::Concern

  included do
    has_many :email_addresses, dependent: :destroy
    validate :at_least_one_email_address, unless: :new_record?
    after_create :create_initial_email_address
  end

  private
    def create_initial_email_address
      email_addresses.create!
    end

    def at_least_one_email_address
      errors.add(:email_addresses, "must have at least one email address") if email_addresses.empty?
    end
end
