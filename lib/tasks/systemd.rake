# lib/tasks/systemd.rake
namespace :systemd do
  task :generate do
    require "erb"
    [ "thruster.service", "sidekiq.service" ].each do |service|
      template = ERB.new(File.read("config/systemd/#{service}.erb"))
      File.write("config/systemd/#{service}", template.result(binding))
    end
  end
end
