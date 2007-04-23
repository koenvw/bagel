class Video < ActiveRecord::Base

  acts_as_content_type

  validates_presence_of :title
  validates_presence_of :url

   def id_url
    "#{id}-#{title.downcase.gsub(/[^a-z1-9]+/i, '-')}"
   end

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title.rubify unless title.nil?
    end
  end

  def intro(words=0, maximum_characters=0)
    if words == 0
      body.split[0..10].collect { |w| w + " " }.to_s
    else
      str = title + body.split[0..words].collect { |w| w + " " }.to_s
      until str.size < maximum_characters
        words -= 1
        str = title + body.split[0..words].collect { |w| w + " " }.to_s
        break if words <= 0
     end
      body.split[0..words].collect { |w| w + " " }.to_s
    end
  end

  def intro_fr(words=0, maximum_characters=0)
    if words == 0
      body_fr.split[0..10].collect { |w| w + " " }.to_s
    else
      str = title + body_fr.split[0..words].collect { |w| w + " " }.to_s
      until str.size < maximum_characters
        words -= 1
        str = title + body_fr.split[0..words].collect { |w| w + " " }.to_s
        break if words <= 0
     end
      body_fr.split[0..words].collect { |w| w + " " }.to_s
    end
  end

end
