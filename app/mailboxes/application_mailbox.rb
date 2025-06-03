class ApplicationMailbox < ActionMailbox::Base
  routing /@starchmail\.com$/i => :newsletter
end
