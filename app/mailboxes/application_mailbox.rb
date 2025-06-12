class ApplicationMailbox < ActionMailbox::Base
  rescue_from ActionMailbox::Router::RoutingError do
    inbound_email.incinerate
  end

  routing /@starchmail\.com$/i => :newsletter
end
