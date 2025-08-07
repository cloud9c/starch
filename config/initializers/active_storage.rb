Rails.application.config.to_prepare do
  Rails.application.config.active_storage.previewers += [ ActiveStorage::Previewer::EpubPreviewer ]
end
