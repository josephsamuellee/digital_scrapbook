Rails.application.config.after_initialize do
  FileUtils.mkdir_p(Rails.application.config.x.data_root.join("memories"))
end
