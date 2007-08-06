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

      if generator.nil?
        "no generator found for this content_type '#{self.class.to_s}' with website_id '#{website_id}'"
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
      sitems.any? { |sitem| sitem.website_id == site_id and sitem.is_published? }
    end

    def has_hidden_sitem?
      sitems.any? { |sitem| !sitem.is_published? }
    end

    def relation(name, options = {})
      options.assert_valid_keys [:reverse]
      # look up relation
      relation = Relation.find_by_name(name, :include => :content_type)
      return if relation.nil?
      # see if we want the relation in the reverse direction (from/to) #FIXME: shouldn't we use the reverse_name for the relation?
      from_sobject_id = options[:reverse] == true ? "to_sobject_id" : "from_sobject_id"
      to_sobject_id = options[:reverse] == true ? "from_sobject_id" : "to_sobject_id"
      # look up first relationship for this relation
      relationship = Relationship.find(:first, :conditions => ["#{from_sobject_id} = ? AND relation_id = ?",self.sobject.id,relation.id], :limit=>1, :order => "position ASC")
      unless relationship.nil?
        # by using "type" we can save ourselves 1 extra query (sobject will be joined with the contentype directly)
        # FIXME: we do extra queries to find out the content type.
        if options[:reverse] == true
          type = relationship.from.content_type.downcase.to_sym
        else
          type = relationship.to.content_type.downcase.to_sym
        end
        s = Sobject.find(relationship.send(to_sobject_id), :include => type)
        s.send(type)
      end
    end

    def relations(name = nil)
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
      relations.map { |relation| relation.to.content }
    end

    def tags(parent_name = nil)
      if parent_name
        parent_tag = Tag.find_by_name(parent_name)
        sobject.tags.find(:first,:conditions => ["parent_id=?",parent_tag.id]) if parent_tag
      else
        sobject.tags
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
      if sitem.nil?
        add_sitem(website_id)
      else
        sitem.is_published = true
        sitem.save
        sitem
      end
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
      added_relations.each_with_index { |relation,index| relation.update_attribute :position, index }
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

    def save_relationships(relations_id,relations_cat_id,delete_id,delete_cat_id,reverse_relations=false)
      $stderr.puts 'DEPRECATION WARNING: save_relationships() is deprecated; use save_relations instead.'
      unless relations_id.nil?
        relations=relations_id.zip(relations_cat_id)
        # keep only the unique elements
        relations.uniq
      else
        relations=Array.new
      end
      relations_delete=delete_id.zip(delete_cat_id) unless delete_id.nil?

      # delete elements (if there where items in the first place)
      unless delete_id.nil?
        relations_delete.each do |d|
          if relations.find{|r| r==d}.nil?
            if reverse_relations
              Relationship.destroy_all "to_sobject_id=#{sobject.id} AND relation_id=#{d[1]}"
            else
              Relationship.destroy_all "from_sobject_id=#{sobject.id} AND relation_id=#{d[1]}"
            end
          end
        end
      end

      # only add if there are items submitted
      unless relations_id.nil?
        p=1
        relations.each do |i|
            # first check if the item doesn't exist
            if reverse_relations
              relationship=Relationship.find(:all,:conditions => "to_sobject_id=#{sobject.id} AND from_sobject_id=#{i[0]} AND relation_id=#{i[1]}")
            else
              relationship=Relationship.find(:all,:conditions => "from_sobject_id=#{sobject.id} AND to_sobject_id=#{i[0]} AND relation_id=#{i[1]}")
            end
            if relationship.empty?
               if reverse_relations
                 Relationship.create :to_sobject_id=>sobject.id,:from_sobject_id=>i[0],:relation_id=>i[1],:position=>p
               else
                 Relationship.create :from_sobject_id=>sobject.id,:to_sobject_id=>i[0],:relation_id=>i[1],:position=>p
               end
            else
               relationship.first.position=p
               relationship.first.save
            end
            p+=1
        end
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
      if sitems.empty?
        Website.find(:all).each do |website|
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
