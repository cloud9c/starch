module FeedHelper
  extend self

  def parse(content)
    Feedjira.parse(content)
  end
end
