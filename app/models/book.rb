class Book < ActiveRecord::Base
  acts_as_content_type

  validates_presence_of :title

   def id_url
    "#{id}-#{title.downcase.gsub(/[^a-z1-9]+/i, '-')}"
   end

  def intro(words=0, maximum_characters=0)
    return "" if attributes['intro'].nil?
    if words == 0 and attributes['intro'].size == 0
      attributes['intro'].split[0..10].collect { |w| w + " " }.to_s
    elsif attributes['intro'].size==0 or words != 0
      str = title + attributes['intro'].split[0..words].collect { |w| w + " " }.to_s
      until str.size < maximum_characters
        words -= 1
        str = title + attributes['intro'].split[0..words].collect { |w| w + " " }.to_s
        break if words <= 0
      end
      attributes['intro'].split[0..words].collect { |w| w + " " }.to_s
    else
      attributes['intro']
    end
  end

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end

end
