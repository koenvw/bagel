# Stolen from file_column's file_compat.rb

module FileCompat # :nodoc:
  def original_filename
    File.basename(path)
  end
  
  def size
    File.size(path)
  end
  
  def local_path
    path
  end
  
  def content_type
    nil
  end
end
