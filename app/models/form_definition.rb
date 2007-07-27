class FormDefinition < ActiveRecord::Base
  has_many :forms, :dependent => :destroy
  # FIXME: why does a FormDefinition need sitems ???
  #has_many :sitems, :as => :content, :dependent => :destroy
  validates_presence_of :name, :template

  #
  def template_view(site)
    website_id = Website.find_by_name(site).id
    generator_name = site + '_' +self.name.downcase.gsub(/ /,'_')
    gen = Generator.find_by_name_and_website_id_and_content_type(generator_name,website_id, "form")
    if gen.nil?
      "generator '#{generator_name}' not found"
    else
      gen.template
    end
  end

  def template_form(site)
    website_id = Website.find_by_name(site).id
    generator_name = site + '_' + self.name.downcase.gsub(/ /,'_')
    gen = Generator.find_by_name_and_website_id_and_content_type(generator_name,website_id, "formdefinition")
    if gen.nil?
      "generator '#{generator_name}' not found"
    else
      gen.template
    end
  end

  # Liquid support

  def to_liquid
    FormDefinitionDrop.new(self)
  end

end
