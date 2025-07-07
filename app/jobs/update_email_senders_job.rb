class UpdateEmailSendersJob < ApplicationJob
  def perform(*args)
    jobs = []
    window = 12.hours
    count = EmailSender.count
    index = 0

    EmailSender.find_each do |feed|
      delay = index * window / count
      jobs << UpdateEmailSenderJob.new(feed.id).set(wait: delay)
      index += 1
    end

    ActiveJob.perform_all_later(jobs)
  end
end
