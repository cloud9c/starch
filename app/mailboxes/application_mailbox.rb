class ApplicationMailbox < ActionMailbox::Base
  routing /@starchmail\.com$/i => :newsletter
  routing all: :trash
end
