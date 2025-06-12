class TrashMailbox < ApplicationMailbox
  def process
    inbound_email.incinerate
  end
end
