desc 'convert picture_file_system images with latest settings'
task :update_picture_versions => :environment do
  PictureFileSystem.find(:all,:conditions => "parent_id is null", :order => "created_on DESC").each do |image|
    puts image.public_filename
    image.uploaded_data = image.create_temp_file
    image.save!
  end
end
