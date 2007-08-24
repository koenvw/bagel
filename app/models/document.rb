class Document < MediaItem
  acts_as_content_type
  has_attachment :storage       => :file_system,
                 :path_prefix     => 'public/assets/documents', 
                 #:content_type  => ["application/msword","application/pdf"],
                 :size            => 0..15.megabyte # FIXME: yes we allow 0, sometimes the size is 0 after succesfull upload? 
  validates_as_attachment
  validates_presence_of :title

  FILTERS = {
    'application/pdf'     => 'pdf_filter',
    'application/msword'  => 'msword_filter'
  }

  after_attachment_saved do |record|
    # Extract text
    record.extract_text
  end

  #def full_filename(thumbnail=nil)
  #  'file://' + public_filename(thumbnail)
  #end

  #def public_filename(thumbnail=nil)
  #  '/media_item_from_db?id=' + id.to_s
  #end

  def extract_text
    # Create temporary working directory directory
    FileUtils.mkdir_p(File.join(RAILS_ROOT, 'tmp', 'documents'))

    # Find path to convert script
    convert_script = File.join(RAILS_ROOT, 'script', FILTERS[self.content_type])

    # Get paths to temp in/out file
    temp_file_in = self.create_temp_file.path
    temp_file_out = File.join(RAILS_ROOT, 'tmp', 'documents',"#{self.id}.txt")

    # Convert
    if system "#{convert_script} #{temp_file_in} #{temp_file_out}"
      self.content = File.read(temp_file_out)
      File.unlink(temp_file_out)
    else
      self.content = "NO CONTENT"
    end
    self.save
  end

end
