class BusinessRule < ActiveRecord::Base

  validates_presence_of :name
  validates_presence_of :content_type
  validates_presence_of :code

  belongs_to :content_type

  def passes_for(obj)
    return false if obj.nil?
    @rule_errors = []
    lambda { eval(code) }.call
    @rule_errors.blank?
  end

  def rule_errors
    @rule_errors ||= []
  end

  def non_matching_objects
    sobjects = Sobject.find(:all, :conditions => [ 'content_type_id = ?', content_type.id ], :include => content_type.core_content_type.downcase, :limit => 9999)
    contents = sobjects.map { |so| so.content }
    contents.reject { |x| x.nil? || passes_for(x) }
  end

  ### Helper functions

  # FIXME: move this to a module under lib/ ?

  def require_tag(obj, tag_name, params={})
    params[:message] ||= "Tag named '#{tag_name}' must be present but is not."

    return unless obj

    tag = Tag.find_by_name(tag_name)
    tag_present = obj.sobject.tags.include?(tag)
    tag_present = tag.children.any? { |child_tag| obj.sobject.tags.include?(child_tag) } unless tag_present

    rule_errors << params[:message] unless tag_present
  end

  def require_relation(obj, relation_names, params={})
    params[:message] ||= (relation_names.to_a.map {|relation_name| "relation named '#{relation_name}'"}.to_sentence(:connector => "or") + " must be present but is not.").capitalize
    return unless obj

    # user may give multiple relation_names, having at least 1 relation from the list is valid
    valid = false
    relation_names.to_a.each do |relation_name|
      relation_present = obj.sobject.relations_as_from.any? { |r| r.relation.name == relation_name }
      valid = true if relation_present
    end
    rule_errors << params[:message] unless valid
  end

  def require_translation(obj, language, params={})
    params[:message] ||= "Translation to '#{language}' must be present but is not."

    return unless obj

    translation_present_from = obj.sobject.relations_as_from.any? { |r| r.relation.is_translation_relation? and r.to.language   = language  }
    translation_present_to   = obj.sobject.relations_as_to.any?   { |r| r.relation.is_translation_relation? and r.from.language = language  }

    rule_errors << params[:message] if !translation_present_to and !translation_present_from
  end

  def forbid_website(obj, website, params={})
    params[:message] ||= "Website '#{website}' may not be present but is."

    return unless obj

    website = Website.find_by_name(website)
    website_present = obj.sobject.sitems.map(&:website).include?(website)

    rule_errors << params[:message] if website_present
  end

end
