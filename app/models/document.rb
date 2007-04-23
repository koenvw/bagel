class Document < Media
  acts_as_content_type
  has_attachment :storage => :db_file, :content_type => ["application/msword","application/pdf"]
  validates_as_attachment
  validates_presence_of :title

  # Callback before a thumbnail is saved.  Use this to pass any necessary extra attributes that may be required.
  before_thumbnail_saved do |record, thumbnail|
    #  ...
  end

  # Callback after an image has been resized.
  after_resize do |record, img|
    #  ...
  end

  # Callback after an attachment has been saved either to the file system or the DB.
  # Only called if the file has been changed, not necessarily if the record is updated.
  after_attachment_saved do |record|
    # creating working directory
    FileUtils.mkdir_p(File.join(RAILS_ROOT, 'tmp', 'documents'))
    #
    case record.content_type
      when "application/pdf"
        convert_script = File.join(RAILS_ROOT, 'script', 'convert2text', 'pdf_filter')
        temp_file_in = record.create_temp_file.path
        temp_file_out = File.join(RAILS_ROOT, 'tmp', 'documents',"#{record.id}.txt")
        if system "#{convert_script} #{temp_file_in} #{temp_file_out}"
          buffer = ""
          File.open(temp_file_out).each { |line| buffer << line }
          record.content = buffer
          File.unlink(temp_file_out)
        else
          record.content = "NO CONTENT"
        end
        record.save

      when "application/msword"
        convert_script = File.join(RAILS_ROOT, 'script', 'convert2text', 'msword_filter')
        temp_file_in = record.create_temp_file.path
        temp_file_out = File.join(RAILS_ROOT, 'tmp', 'documents',"#{record.id}.txt")
        if system "#{convert_script} #{temp_file_in} #{temp_file_out}"
          buffer = ""
          File.open(temp_file_out).each { |line| buffer << line }
          record.content = buffer
          File.unlink(temp_file_out)
        else
          record.content = "#{convert_script} #{temp_file_in} #{temp_file_out}"
        end
        record.save

    end
  end

end
