class Document < MediaItem
  acts_as_content_type
  has_attachment :storage       => :db_file,
                 :content_type  => ["application/msword","application/pdf"]
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

  def full_filename(thumbnail=nil)
    'file://' + public_filename(thumbnail)
  end

  def public_filename(thumbnail=nil)
    '/media_item_from_db?id=' + id.to_s
  end

  def extract_text
    # Create temporary working directory directory
    FileUtils.mkdir_p(File.join(RAILS_ROOT, 'tmp', 'documents'))

    # Find path to convert script
    convert_script = File.join(RAILS_ROOT, 'script', FILTERS[record.content_type])

    # Get paths to temp in/out file
    temp_file_in = record.create_temp_file.path
    temp_file_out = File.join(RAILS_ROOT, 'tmp', 'documents',"#{record.id}.txt")

    # Convert
    if system "#{convert_script} #{temp_file_in} #{temp_file_out}"
      record.content = File.read(temp_file_out)
      File.unlink(temp_file_out)
    else
      record.content = "NO CONTENT"
    end
    record.save
  end

end
