class Sobject < ActiveRecord::Base

  # Content
  belongs_to :content,    :polymorphic => true
  belongs_to :ctype,      :foreign_key => "content_type_id", :class_name => "ContentType"
  # The stuff just below this line is used when including other tables in a query
  belongs_to :container,  :foreign_key => "content_id"
  belongs_to :form,       :foreign_key => "content_id"
  belongs_to :generator,  :foreign_key => "content_id"
  belongs_to :media_item, :foreign_key => "content_id"
  belongs_to :link,       :foreign_key => "content_id"
  belongs_to :menu,       :foreign_key => "content_id"
  belongs_to :news,       :foreign_key => "content_id"
  belongs_to :form,       :foreign_key => "content_id"
  belongs_to :event,      :foreign_key => "content_id"
  belongs_to :image,      :foreign_key => "content_id"

  # Sitems
  has_many   :sitems

  # Tags
  has_and_belongs_to_many :tags, :after_add               => :update_cached_tags,
                                 :after_remove            => :update_cached_tags,
                                 :join_table              => "sobjects_tags"

  # Workflow
  has_many   :workflow_actions
  has_many   :workflow_steps, :through => :workflow_actions

  # Relationships
  has_many   :relations_as_from, :foreign_key => 'from_sobject_id', :class_name => 'Relationship', :dependent => :delete_all
  has_many   :relations_as_to,   :foreign_key => 'to_sobject_id',   :class_name => 'Relationship', :dependent => :delete_all
  has_many   :from,  :through => :relations_as_to
  has_many   :to,    :through => :relations_as_from

  # Userstamp
  belongs_to :created_by, :class_name => "AdminUser", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "AdminUser", :foreign_key => "updated_by"

  # Validations
  validates_presence_of :content_id
  validates_presence_of :content_type

  def after_create
    update_cached_tags(nil)
  end

  def ctype_name
    # ctype is not mandatory, so check and return something sensible
    ctype.nil? ? content_type : ctype.name
  end

  def update_cached_tags(tag)
    update_attribute :cached_tag_ids, ";" + tags.map {|c| c.id}.join(";") + ";" unless new_record?
    hash = {}
    tags.each do |cat|
      hash[cat.parent.name] = cat.name unless cat.parent.nil?
    end
    update_attribute(:cached_tags, hash.to_yaml)
  end

  # FIXME: former name was "tags" -> massive breakage
  def cached_tags
    # FIXME: how to make operations on this hash persist to the form ? (eg.: f.data.delete())
    unless read_attribute(:cached_tags) == "" or read_attribute(:cached_tags).nil?
      YAML.load(read_attribute(:cached_tags))
    else
      {}
    end
  end

  # Returns the name of the controller responsible for managing this sobject
  def controller_name
    ( MediaItem::ALLOWED_CLASS_NAMES.include?(self.content_type) ? 'media_item' : self.content_type ).tableize.downcase
  end

  def self.find_with_parameters(options = {})
    # Default options:
    # website_name, website_id, content_types, tags, published_by, limit=5, offset=0, search_string=nil,publish_from=nil,publish_till=nil,conditions=nil,include=nil,order="sitems.publish_from DESC",status="Published"

    options.assert_valid_keys [ :tags, :website, :website_name, :website_id, :published_by,
                                :search_string, :content_types, :publish_from, :publish_till,
                                :status, :published, :current_workflow, :has_workflow, :conditions,
                                :include, :order, :limit, :tags_inverted, :relations, :relationships ]

    # Convert :status option into a :published option
    if options[:status] and !options[:published]
      options[:published] = :all  if options[:status] == :all
      options[:published] = true  if options[:status] == 'Published'
      options[:published] = false if options[:status] == 'Hidden'
    end

    # tags
    unless options[:tags].nil?
      # map elements to ids
      tags = options[:tags].to_a.compact.uniq.map do |tag_id|
        # FIXME: reject non-active tags
        if tag_id.to_i == 0
          # not integer, lookup by name
          tag = Tag.find_by_name(tag_id)
          # raise RecordNotFound if name not found
          if tag.nil? 
            raise ActiveRecord::RecordNotFound.new("Couldn't find tag with name=#{tag_id}")
          else
            tag.id
          end
        else
           tag_id.to_i
        end
      end
      tag_check = "AND (1=0"
      tags.each do |tag_id|
        tag_check << " OR cached_tag_ids LIKE '%;#{tag_id};%' "
      end
      tag_check << ")"
    end
    
    unless options[:tags_inverted].nil?
      # map elements to ids
      tags = options[:tags_inverted].to_a.compact.uniq.map do |tag_id|
        # FIXME: reject non-active tags
        if tag_id.to_i == 0
          # not integer, lookup by name
          tag = Tag.find_by_name(tag_id)
          # raise RecordNotFound if name not found
          if tag.nil? 
            raise ActiveRecord::RecordNotFound.new("Couldn't find tag with name=#{tag_id}")
          else
            tag.id
          end
        else
           tag_id.to_i
        end
      end
      tag_inverted_check = "AND (1=1"
      tags.each do |tag_id|
        tag_inverted_check << " AND cached_tag_ids NOT LIKE '%;#{tag_id};%' "
      end
      tag_inverted_check << ")"
    end
    
    # website_name
    if options[:website]
      if options[:website].to_i == 0 # a string
        website = Website.find_by_name(options[:website])
        raise ActiveRecord::RecordNotFound.new("Couldn't find website with name=#{options[:website]}") if website.nil?
        website_check = " AND sitems.website_id=#{website.id}"
      else # a number
        website_check = " AND sitems.website_id=#{options[:website]}"
      end
    elsif options[:website_name]
      website = Website.find_by_name(options[:website_name])
      raise ActiveRecord::RecordNotFound.new("Couldn't find website with name=#{options[:website_name]}") if website.nil?
      website_check = " AND sitems.website_id=#{website.id}"
    else
      # website_id
      if options[:website_id]
        website_check = " AND sitems.website_id=#{options[:website_id]} AND sitems.is_published=1" # FIXME: status conflicts with status below?
      end
    end

    # relations, feed with relation ids or relation names
    if options[:relations]
      relations = options[:relations].to_a.compact.uniq.map do |element|
        if element.to_i == 0 # a string
          relation = Relation.find_by_name(element)
          raise ActiveRecord::RecordNotFound.new("Couldn't find relation with name=#{element}") if relation.nil?
          relation.id
        else
          element.to_i
        end
      end
      joins = " INNER JOIN relationships ON relationships.relation_id IN (#{relations.join(",")}) AND relationships.from_sobject_id = sobjects.id" unless relations.blank?
    end
    
    # relationships, feed with sobject ids or sobjects 
    if options[:relationships]
      sobject_ids = options[:relationships].to_a.compact.uniq.map do |element|
        if element.is_a? Sobject
          element.id
        else
          element.to_i
        end
      end
      joins = " INNER JOIN relationships ON relationships.to_sobject_id IN (#{sobject_ids.join(",")}) AND relationships.from_sobject_id = sobjects.id" unless sobject_ids.blank?
    end

    # published by
    if options[:published_by]
      users = options[:published_by].to_a.compact.uniq.map do |user|
        (user.to_i == 0) ? AdminUser.find_by_username(user).id : user.to_i
      end
      published_by_check = " AND sobjects.updated_by IN (#{users.join(",")})"
    end
    
    # search_string
    unless options[:search_string].blank?
      search_check = "AND (sobjects.name LIKE '%#{ActiveRecord::Base.connection.quote_string(options[:search_string])}%')"
    end
    
    # content_types
    if options[:content_types]
      # map elements to ids
      ctypes = options[:content_types].to_a.compact.uniq.map { |content_type_id|
        if content_type_id.to_i == 0
          # not integer, look up by name
          content_type = ContentType.find_by_name(content_type_id)
          # raise RecordNotFound if name not found
          if content_type.nil? 
            raise ActiveRecord::RecordNotFound.new("Couldn't find content_type with name=#{content_type_id}")
          else
            content_type.id
          end
        else
          # content type is integer
          content_type_id
        end
      }
      content_type_check = " AND sobjects.content_type_id IN (#{ctypes.join(",")})" unless ctypes.blank?
    end
    
    # publish_from
    if options[:publish_from]
      publish_from_check = " AND sitems.publish_from >= '#{options[:publish_from].to_time.strftime("%Y-%m-%d %H:%M:%S")}'"
    elsif options[:status] != :all
      publish_from_check = " AND sitems.publish_from<now()"
    else
      publish_from_check = " AND sitems.publish_from>'0001-01-01'"
    end
    
    # publish_till
    if options[:publish_till]
      publish_till_check = " AND sitems.publish_from <= '#{options[:publish_till].to_time.strftime("%Y-%m-%d %H:%M:%S")}'"
    elsif options[:status] != :all
      publish_till_check = " AND (sitems.publish_till>now() OR sitems.publish_till IS NULL)"
    else
      publish_till_check = " AND (sitems.publish_till<'9999-01-01' OR sitems.publish_till IS NULL)"
    end
    
    # is published
    if options[:published]
      if options[:published] == :all
        status_check = ' '
      else
        status_check = " AND sitems.is_published='#{options[:published] ? '1' : '0'}'"
      end
    else
      status_check = ' AND sitems.is_published = "1" AND sitems.publish_from < now()'
    end
    
    # workflow
    if options[:has_workflow]
      workflow_check = ""; workflows = []
      workflow_check << " AND sobjects.content_type_id IN (#{wf_step.workflow.content_types.map{|ct|ct.id}.join(",")})"
      options[:has_workflow].to_a.each do |step_id|
        # FIXME: not efficient with many step_ids
        wf_step = WorkflowStep.find(step_id)
        workflow_check << " AND EXISTS (SELECT * FROM workflow_actions WHERE sobject_id=sobjects.id AND workflow_step_id=#{step_id})"
      end
    end
    if options[:current_workflow]
      workflow_check = ""; workflows = []
      current_step = WorkflowStep.find(options[:current_workflow])
      workflow_check << " AND sobjects.content_type_id IN (#{current_step.workflow.content_types.map{|ct|ct.id}.join(",")})"
      current_step.workflow.workflow_steps.each do |step|
        if current_step.optional? || !step.optional? # skip optional steps unless the request step is optional # FIXME: this only works when optional steps come first?
          if step.position > current_step.position
            workflow_check << " AND NOT EXISTS (SELECT * FROM workflow_actions WHERE sobject_id=sobjects.id AND workflow_step_id=#{step.id})"
          else
            workflow_check << " AND EXISTS (SELECT * FROM workflow_actions WHERE sobject_id=sobjects.id AND workflow_step_id=#{step.id})"
          end
        end
      end
    end
    
    # includes
    includes = :sitems
    if options[:include]
      includes = [includes,options[:include]]
    end

    find(
      :all,
      :conditions => "1=1
        #{status_check}
        #{website_check}
        #{tag_check}
        #{tag_inverted_check}
        #{search_check}
        #{content_type_check}
        #{publish_from_check}
        #{publish_till_check}
        #{published_by_check}
        #{workflow_check}
        #{options[:conditions]}
      ",
      :include => includes,
      :joins   => joins||=nil,
      :limit   => options[:limit]  || 5,
      :offset  => options[:offset] || 0,
      :order   => options[:order]  || "sitems.publish_from DESC"
    )
  end

  ########## DEPRECATED

  def self.list(site, content_types, tags, limit=5, offset=0, search_string="")
    $stderr.puts('DEPRECATION WARNING: Sobject.list is deprecated; please use Sobject.find_with_parameters')
    tag_check = "AND (1=0"
    tags.each do |tag_name|
      tag = Tag.find_by_name(tag)
      unless tag.nil?
        tag_check << " OR cached_category_ids LIKE '%;#{tag.id};%' "
      end
    end
    #FIXME: TA is an exception because it does not have a tag (better exclude tags than include them ??)
    tag_check << " OR sobjects.content_type ='TestArticle'"
    tag_check << " OR sobjects.content_type ='Book')"
    if search_string.size > 0
      search_check = "AND (name LIKE '%#{search_string}%')"
    else
      search_check = ""
    end

    find(
      :all,
      :conditions=>"
        sitems.website_id=#{Website.find_by_name(site).id}
        AND (sitems.publish_till<now() OR sitems.publish_till IS NULL)
        AND sitems.publish_from<now()
        AND sitems.status='Published'
        #{tag_check}
        #{search_check}
        AND sobjects.content_type IN (#{"'" + content_types.join("','") + "'"})
      ",
      :include=>:sitems,
      :limit=>limit,
      :offset=>offset,
      :order=>"sitems.publish_from DESC"
    )
  end

  def categories
    $stderr.puts('DEPRECATION WARNING: Sobject.categories is deprecated; please use Sobject.tags')
    tags
  end

end
