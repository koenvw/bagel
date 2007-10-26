# Extends an ActiveRecord class with bagel-content-type functionality
module ActsAsContentType

  def self.append_features(base) #:nodoc:
    super
    base.extend(ClassMethods)
  end

  module ClassMethods #:nodoc:

    def acts_as_content_type(options=nil)
      has_many :sitems, :as => :content, :dependent => :destroy
      has_one :sobject, :foreign_key => :content_id, :conditions => "sobjects.content_type='#{self}'", :dependent => :destroy

      class_eval do
        include HelperFields
        include HelperMethods
        include Callbacks
      end
    end

  end

  module HelperFields

    def generator(website_id)
      # Find generator by content_type
      generator = Generator.find_by_website_id_and_content_type_id(website_id, self.ctype.id)

      # Find generator by core_content_type
      generator ||= Generator.find_by_website_id_and_core_content_type(website_id, self.class.to_s)

      # FIXME: make website a multiselect for a generator
      # so we can specify that 1 generator works for a set of websites

      # Find generator by content_type without website
      generator ||= Generator.find_by_content_type_id(self.ctype.id)

      # Find generator by core_content_type without website
      generator ||= Generator.find_by_core_content_type(self.class.to_s)

      if generator.nil?
        raise "no generator found for this content_type '#{self.class.to_s}' with website_id '#{website_id}'"
      end

      generator
    end

    def template(website_id)
      # Update click_count (.find + .increment is faster than .update_all
      sitem = sitems.find_by_website_id(website_id)
      sitem.increment!(:click_count) unless sitem.nil?

      # Find generator
      g = generator(website_id)

      # Return generator and its template
      [ g, g.template ]
    end

    def intro_or_body
      (intro.blank?) ? body : intro
    end

    def intro(words=0, maximum_characters=0)
      $stderr.puts 'DEPRECATION WARNING: .intro(words,max_chars) is deprecated; use truncate_with_words instead.'
      # check if we are working on a object that can have an intro
      if respond_to?(:title) && respond_to?(:body) && !title.blank? && !body.blank?

        # if we don't have a number of words specified and our object does not have an intro field
        if words == 0 and intro.blank?
          # return the first 10 word of the body
          body.split[0..10].join(" ")

        # if we have a number of words to return and still no intro field
        elsif words != 0 and intro.blank?
          # 
          maximum_characters ||= (+1.0/0.0) # infinity!

          # see how many words can fit in maximum_characters
          str = title + body.split[0..words].join(" ")
          until str.size < maximum_characters
            words -= 1
            str = title + body.split[0..words].join(" ")
            break if words <= 0
          end
          body.split[0..words].join(" ")
        else
          attributes['intro']
        end
      else
          return ""
      end
    end

    def id_url
      "#{id}-#{title.downcase.gsub(/[^a-z0-9]+/i, '-')}"
    end

    def publish_date(site_id)
      #FIXME: also support website_name
      date = sitems.find_by_website_id(site_id).publish_from
      if date.nil?
        created_on
      else
        date
      end
    end

    def published_by
      sobject.updated_by.fullname if sobject.updated_by
    end

    def is_published?(site_id)
      sitems.any? { |si| si.website_id == site_id and si.published_async? and si.publish_from < Time.now }
    end

    def has_hidden_sitem?
      sitems.any? { |sitem| !sitem.published_async? }
    end

    def relation(name, options = {})
      # FIXME: option :reverse is a bad idea => there can be multiple reverse relations than can only be distinguished by their content-type (add extra option content-type?)
      options.assert_valid_keys [:reverse, :website]
      # look up relation
      relation = Relation.find_by_name(name, :include => :content_type)
      raise ActiveRecord::RecordNotFound.new("Couldn't find relation with name=#{name}") if relation.nil?
      # see if we want the relation in the reverse direction (from/to) #FIXME: shouldn't we use the reverse_name for the relation?
      from_sobject_id = options[:reverse] == true ? "to_sobject_id" : "from_sobject_id"
      to_sobject_id = options[:reverse] == true ? "from_sobject_id" : "to_sobject_id"
      # look up first relationship for this relation
      relationship = Relationship.find(:first, :conditions => ["#{from_sobject_id} = ? AND relation_id = ?",self.sobject.id,relation.id], :limit=>1, :order => "position ASC")
      unless relationship.nil?
        # by using "type" we can save ourselves 1 extra query (sobject will be joined with the contentype directly)
        # FIXME: we do extra queries to find out the content type.
        if options[:reverse] == true
          type = relationship.from.content_type
        else
          type = relationship.to.content_type
        end
        # FIXME: making an exception for media_items (Picture* are really MediaItems)
        type = 'media_item' if MediaItem::ALLOWED_CLASS_NAMES.include?(type)
        s = Sobject.find(relationship.send(to_sobject_id), :include => type.downcase.to_sym)
        # FIXME why not use .content? => :include => type
        item = s.send(type.downcase.to_sym)
        item = nil if options[:website] && item && !item.is_published?(options[:website])
        return item
      end
    end

    def relations(name = nil, options = {})
      options.assert_valid_keys [ :website ]
      return if self.sobject.nil?
      if name
        # look up relation
        relation = Relation.find_by_name(name)
        return if relation.nil?
        relations = Relationship.find(:all, :conditions => ["relation_id =? AND from_sobject_id = ?",relation.id,self.sobject.id], :order=>"relationships.position", :include => [:to])
      else
        # all relations
        relations = Relationship.find(:all, :conditions => ["from_sobject_id = ?",self.sobject.id], :order=>"relationships.position", :include => [:to])
      end
      # map to actual content objects
      relations.map! { |relation| relation.to.content }
      # reject non published object if requested
      relations.reject! { |content| !content.is_published?(options[:website]) } if options[:website]
      return relations
    end

    def tags(parent_name = nil)
      if parent_name
        parent_tag = Tag.find_by_name(parent_name)
        sobject.tags.find(:first,:conditions => ["parent_id=? and active=1",parent_tag.id]) if parent_tag
      else
        sobject.tags.reject{|tag| !tag.active?}
      end
    end

    def type_id
      sobject.content_type_id
    end

    def ctype
      sobject.ctype
    end

    def ctype_name
      sobject.ctype_name
    end

    def created_by
      sobject.created_by
    end

    def updated_by
      sobject.updated_by
    end

    def controller_name
      sobject.controller_name
    end

    def sitem_for(website)
      sitems.select { |s| s.website == website }.first
    end

    def current_workflow_step
      unless sobject.workflow_actions.empty?
        sobject.workflow_actions.sort_by { |wa| wa.workflow_step.position }.reverse.first.workflow_step
      end
    end

    def current_workflow_step_name
      step = current_workflow_step
      step && step.name || ''
    end

  end

  module HelperMethods

    def add_sitem(website_id)
      # build a sitem, default status to NOT published
      sitems.build :website_id => website_id, :publish_date => Date.today, :publish_from => Time.now, :is_published => false 
    end

    def add_sitem_unless(website)
      if website.is_a?(Fixnum)
        website_id = Website.find(website).id
      elsif website.is_a?(String)
        website_id = Website.find_by_name(website).id
      else
        website_id = website.id
      end
      sitem = sitems.find_by_website_id(website_id)
      if sitem.nil? # FIXME: sitem can never be nil? (its always an array, sometimes empty)
        add_sitem(website_id)
      else
        sitem.is_published = true
        sitem.save
        sitem
      end
    end

    def save_language(language)
      sobject.language = language
      sobject.save
    end

    def save_tags(tags)
      sobject.tags.clear
      sobject.cached_tags = ""
      sobject.cached_tag_ids = ""
      unless tags.nil?
        tags = tags.split(",") if tags.is_a?(String)
        tags.uniq.each do |tag_id|
          sobject.tags<< Tag.find(tag_id)
        end
      end
    end

    def add_tag_unless(tag)
      sobject.tags << tag unless tag.nil? || sobject.tags.exists?(tag.id)
    end

    def remove_tag_unless(tag)
      sobject.tags.delete(tag) if !tag.nil? && sobject.tags.exists?(tag.id)
    end

    def type_id=(content_type_id)
      #FIXME this does not work if sobject is not assigned yet (Item.create :type_id => , ...)
      sobject.content_type_id = content_type_id
    end

    def prepare_sitems(params)
      unless params.blank?
        params.each do |key,new_sitem|
          # we use .select b/c find_by_website_id does not work for new records
          wsitems = sitems.select {|v| v.website_id == new_sitem[:website_id].to_i }
          wsitem = wsitems.first
          # if we are using workflow only admins can change the status
          if ctype && ctype.workflow
            if AdminUser.current_user.is_admin?
              new_sitem[:is_published] = new_sitem.has_key?(:is_published)
            end
          else
            new_sitem[:is_published] = new_sitem.has_key?(:is_published)
          end
          merged_attributes = wsitem.attributes.merge(new_sitem)
          wsitem.attributes = merged_attributes
        end
      end
    end

    def set_updated_by(params)
      if params[:sobject]
        s = sobject
        s.record_userstamps = false
        if AdminUser.exists?(params[:sobject][:updated_by])
          s.updated_by = AdminUser.find(params[:sobject][:updated_by])
          # FIXME: is the Userstamp lib broken ? created_by does never seem to be initialized.
          s.created_by ||= AdminUser.find(params[:sobject][:updated_by])
          s.save
        end
      end
    end

    # relations is a string with this format: 1-2,2-3,... => (to_sobject_id-relation_id)
    def save_relations(relations)
      current_relations = sobject.relations_as_from
      added_relations = []
      unless relations.nil?
        elements = relations.split(",")
        elements.each do |element|
          to_sobject_id = element.split("-")[0]
          relation_id = element.split("-")[1]
          added_relations << add_relation_unless(to_sobject_id,relation_id)
        end
      end
      # remove removed relationships
      (current_relations - added_relations).each { |relation| relation.destroy }
      # fix positions
      added_relations.each_with_index { |relation,index| relation.update_attribute :position, index if relation.valid? }
    end

    def add_relation_unless(to_sobject_id,relation_id)
      Relationship.find_or_create_by_from_sobject_id_and_to_sobject_id_and_relation_id(sobject.id,to_sobject_id,relation_id)
    end

    def save_workflow(step_ids)
      return if step_ids.nil?
      step_ids.each do |step_id|
        wf_step = WorkflowStep.find(step_id)
        if wf_step.is_final?
          # FIXME: how do we know on which website to publish ???
          sitems.each do |sitem| sitem.is_published = true; sitem.save end
        end
        WorkflowAction.create :sobject_id => sobject.id, :admin_user_id => AdminUser.current_user.id, :workflow_step_id => step_id
      end
    end

    def find_tags_with_parent_id(parent_id)
      # FIXME:
      candidates = sobject.tags.select{|c| c.parent_id == parent_id }
      if candidates.size > 0
        return candidates.first
      end
    end

  end

  module Callbacks

    def validate
      unless sobject.ctype.nil?
        sobject.ctype.business_rules.each do |rule|
          # Call rule
          unless rule.passes_for(self)
            # Add errors
            rule.rule_errors.each { |error| errors.add_to_base(error) }
          end
        end
      end
    end

    def after_initialize
      # we need to prepare these to make the forms work on new Objects.
      # its very important to only do this on new records (otherwise .find() will trigger this for every object)
      if new_record?
        prepare_sobject
        create_default_sitems
      end
    end

    def create_default_sitems
      # prepare a sitem for each Website
      Website.find(:all).each do |website|
        sitem = sitems.select {|v| v.website_id == website.id }
        if sitem.blank?
          add_sitem(website.id) 
        end
      end
    end

    def prepare_sobject
      self.build_sobject(:content_type => self.class.to_s) if sobject.nil?
      sobject.name = title if respond_to?(:title)
    end

    # create
    def before_save
      prepare_sobject
    end

    def after_save
      sitems.each { |sitem| sitem.sobject_id = sobject.id; sitem.save! } if self.respond_to?("sitems")
      # FIXME: has_one relationships should automatically be saved ?
      sobject.save if valid?
    end

  end

end
