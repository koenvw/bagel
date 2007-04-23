class GeneratorFile < ActiveRecord::Base
  belongs_to :generator
  validates_presence_of :name
  validates_presence_of :generator_id
  validates_presence_of :file_path

  def write_file()
    html = render_to_string :inline => generator.template
    File.open(file_path, "w") do |file|
      file << html
    end
  end

end
