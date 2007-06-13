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

    def template(website_id)
      # update click_count (.find + .increment is faster than .update_all
      sitem = sitems.find_by_website_id(website_id)
      sitem.increment!(:click_count) unless sitem.nil?
      # find generator
      generator = Generator.find_by_website_id_and_content_type(website_id, self.class.to_s)
      if generator.nil?
        "no generator found for this content_type '#{self.class.to_s}' with website_id '#{website_id}'"
      else
        generator.template
      end
    end

    def intro_or_body
      if intro.nil? or intro.size == 0
        body
      else
        intro
      end
    end

    def intro(words=0, maximum_characters=0)
      if respond_to?(:title) && respond_to?(:body)
        if words == 0 and (attributes['intro'].nil? or attributes['intro'].size == 0)
          body.split[0..10].collect { |w| w + " " }.to_s
        elsif (attributes['intro'].nil? or attributes['intro'].size == 0) or words != 0
          str = title + body.split[0..words].collect { |w| w + " " }.to_s
          until str.size < maximum_characters
            words -= 1
            str = title + body.split[0..words].collect { |w| w + " " }.to_s
            break if words <= 0
          end
          body.split[0..words].collect { |w| w + " " }.to_s
        else
          attributes['intro']
        end
      end
    end

    def id_url
      "#{id}-#{title.downcase.gsub(/[^a-z1-9]+/i, '-')}"
    end

    def publish_date(site_id)
      date = sitems.find_by_website_id(site_id).publish_from
      if date.nil?
        created_on
      else
        date
      end
    end

    def is_published?(site_id)
      true if sitems.find(:all,:conditions=>"sitems.publish_from<now() AND sitems.website_id=#{site_id} AND sitems.status='Published'").size>0
    end

    def has_hidden_sitem?
      result = false
      sitems.each {|sitem| result = true if sitem.status == "Hidden" }
      result
    end

    def relation(name)
      # look up relation
      relation = Relation.find_by_name(name, :include => :content_type)
      return if relation.nil?
      # look up first relationship for this relation
      relationship = Relationship.find(:first, :conditions => ["from_sobject_id = ? AND category_id = ?",self.sobject.id,relation.id], :limit=>1, :order => "position ASC")
      unless relationship.nil?
        # by using "type" we can save ourselves 1 extra query (sobject will be joined with the contentype directly)
        # FIXME: this requires extra_info to be filled -> BROKEN NOW!!
        type = relation.content_type.core_content_type.downcase.to_sym
        s = Sobject.find(relationship.to_sobject_id, :include => type)
        s.send(type)
      end
    end

   def relations(name)
      # look up relation
      relation = Relation.find_by_name(name)
      return if self.sobject.nil? or relation.nil?
      relations = Relationship.find(:all, :conditions => ["category_id =? AND from_sobject_id = ?",relation.id,self.sobject.id], :order=>"relationships.position", :include => [:to])
      relations.map { |relation| relation.to.content }
    end

    def tags
      sobject.tags
    end

  end

  module HelperMethods

    def add_sitem(website_id)
      # build a sitems, default status to NOT published
      sitems.build :website_id => website_id, :publish_date => Date.today, :publish_from => Time.now, :status => "0"
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
        sitem.status = "1"
        sitem.save
        sitem
      end
    end

    def save_tags(tags)
      sobject.tags.clear
      sobject.cached_categories = ""
      sobject.cached_category_ids = ""
      unless tags.nil?
        tags = tags.split(",") if tags.is_a?(String)
        tags.each do |tag_id|
          sobject.tags<< Tag.find(tag_id)
        end
      end
    end

    def add_tag_unless(tag)
      sobject.tags << tag unless sobject.tags.exists?(tag.id)
    end

    def remove_tag_unless(tag)
      sobject.tags.delete(tag) if sobject.tags.exists?(tag.id)
    end

    def type_id=(content_type_id)
      #FIXME this does not work if sobject is not assigned yer (Item.create :type_id => , ...)
      sobject.content_type_id = content_type_id
    end

    def type_id
      sobject.content_type_id
    end

    def ctype
      sobject.ctype
    end

    def prepare_sitems(params)

      params.each do |key,new_sitem|
        # we use .select b/c find_by_website_id does not work for new records
        wsitems = sitems.select {|v| v.website_id == new_sitem[:website_id].to_i }
        wsitem = wsitems.first
        # workaround for checkboxes that do not return value when not set
        new_sitem[:status] = "0" unless new_sitem.has_key?(:status)
        merged_attributes = wsitem.attributes.merge(new_sitem)
        wsitem.attributes = merged_attributes
      end
    end

    def set_updated_by(params)
      if params[:sobject]
        s = sobject
        s.record_userstamps = false
        if AdminUser.exists?(params[:sobject][:updated_by])
          s.updated_by = AdminUser.find(params[:sobject][:updated_by])
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
      Relationship.find_or_create_by_from_sobject_id_and_to_sobject_id_and_category_id(sobject.id,to_sobject_id,relation_id)
    end

    def save_workflow(step_ids)
      return if step_ids.nil?
      step_ids.each do |step_id|
        wf_step = WorkflowStep.find(step_id)
        if wf_step.is_final?
          # FIXME: how do we know on which website to publish ???
          sitems.each do |sitem| sitem.status = "Published"; sitem.save end
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
              Relationship.destroy_all "to_sobject_id=#{sobject.id} AND category_id=#{d[1]}"
            else
              Relationship.destroy_all "from_sobject_id=#{sobject.id} AND category_id=#{d[1]}"
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
              relationship=Relationship.find(:all,:conditions => "to_sobject_id=#{sobject.id} AND from_sobject_id=#{i[0]} AND category_id=#{i[1]}")
            else
              relationship=Relationship.find(:all,:conditions => "from_sobject_id=#{sobject.id} AND to_sobject_id=#{i[0]} AND category_id=#{i[1]}")
            end
            if relationship.empty?
               if reverse_relations
                 Relationship.create :to_sobject_id=>sobject.id,:from_sobject_id=>i[0],:category_id=>i[1],:position=>p
               else
                 Relationship.create :from_sobject_id=>sobject.id,:to_sobject_id=>i[0],:category_id=>i[1],:position=>p
               end
            else
               relationship.first.position=p
               relationship.first.save
            end
            p+=1
        end
      end
    end

    def find_category_with_parent_id(parent_id)
      # FIXME:
      candidates = sobject.categories.select{|c| c.parent_id == parent_id }
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

    def prepare_sitem
      #dummy, can be overridden if needed
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
    end

    # create
    def before_save
      prepare_sitem # just to make ourselves consistent
      prepare_sobject
    end

    def after_save
      sitems.each { |sitem| sitem.sobject_id = sobject.id; sitem.save! } if self.respond_to?("sitems")
      # FIXME: has_one relationships should automatically be saved ?
      sobject.save
    end

  end

end
