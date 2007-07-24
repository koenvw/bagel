class Sobject < ActiveRecord::Base
  belongs_to :content, :polymorphic => true
  #FIXME: need to add new content_types here
  # also ... where is this used ? -> is used when you want to include these tables in find_with_parameters
  belongs_to :book, :foreign_key => "content_id"
  belongs_to :container, :foreign_key => "content_id"
  belongs_to :form, :foreign_key => "content_id"
  belongs_to :gallery, :foreign_key => "content_id"
  belongs_to :generator, :foreign_key => "content_id"
  belongs_to :image, :foreign_key => "content_id"
  belongs_to :link, :foreign_key => "content_id"
  belongs_to :menu, :foreign_key => "content_id"
  belongs_to :news, :foreign_key => "content_id"
  belongs_to :page, :foreign_key => "content_id"
  belongs_to :form, :foreign_key => "content_id"
  belongs_to :event, :foreign_key => "content_id"
  # content_type
  belongs_to :ctype, :foreign_key => "content_type_id", :class_name => "ContentType"
  # "tags"
  has_and_belongs_to_many :tags, :after_add => :update_cached_tags, :after_remove => :update_cached_tags,
                          :join_table => "categories_sobjects", :association_foreign_key => "category_id"
                          #FIXME: rename category_sobjects to tags_sobjects
  has_many :sitems
  #workflow
  has_many :workflow_actions
  has_many :workflow_steps, :through => :workflow_actions
  #relationships
  has_many :relations_as_from, :foreign_key => 'from_sobject_id', :class_name => 'Relationship', :dependent => :delete_all
  has_many :relations_as_to, :foreign_key => 'to_sobject_id', :class_name => 'Relationship', :dependent => :delete_all

  has_many :from,  :through => :relations_as_to
  has_many :to,    :through => :relations_as_from

  # userstamp
  belongs_to :created_by, :class_name => "AdminUser", :foreign_key => "created_by"
  belongs_to :updated_by, :class_name => "AdminUser", :foreign_key => "updated_by"

  #validations
  validates_presence_of :content_id
  validates_presence_of :content_type
  #validates_presence_of :content_type_id # don't make this mandatory (menus and generator are not really a content_type)

  #callbacks
  def after_create
    update_cached_tags(nil)
  end

  # ctype is not mandatory, so we check and return something sensible
  def ctype_name
    ctype.nil? ? content_type : ctype.name
  end

  def update_cached_tags(tag)
    update_attribute :cached_category_ids, ";" + tags.map {|c| c.id}.join(";") + ";" unless new_record?
    hash = {}
    tags.each do |cat|
      hash[cat.parent.name] = cat.name unless cat.parent.nil?
    end
    update_attribute(:cached_categories, hash.to_yaml)
  end

  # FIXME: former name was "tags" -> massive breakage
  def cached_tags
    # FIXME: how to make operations on this hash persist to the form ? (eg.: f.data.delete())
    unless read_attribute(:cached_categories) == "" or read_attribute(:cached_categories).nil?
      YAML.load(read_attribute(:cached_categories))
    else
      {}
    end
  end

  def categories
    $stderr.puts('DEPRECATION WARNING: Sobject.categories is deprecated; please use Sobject.tags')
    tags
  end

  # Returns the name of the controller responsible for managing this sobject
  def controller_name
    ( MediaItem::ALLOWED_CLASS_NAMES.include?(self.content_type) ? 'media_item' : self.content_type ).tableize.downcase
  end

  # class methods
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

  def self.find_with_parameters(options = {})
    # website_name, website_id, content_types, tags, published_by, limit=5, offset=0, search_string=nil,publish_from=nil,publish_till=nil,conditions=nil,include=nil,order="sitems.publish_from DESC",status="Published"
    options.assert_valid_keys [:tags,:website,:website_name,:website_id,:published_by,:search_string,:content_types,:publish_from,:publish_till,:status,:current_workflow,:has_workflow,:conditions,:include,:order,:limit,:tags_inverted]
    # tags
    unless options[:tags].nil?
      # map elements to ids
      tags = options[:tags].to_a.map do |tag|
        (tag.to_i == 0) ? Tag.find_by_name(tag).id : tag.to_i
      end
      tag_check = "AND (1=0"
      tags.each do |tag_id|
        tag_check << " OR cached_category_ids LIKE '%;#{tag_id};%' "
      end
      tag_check << ")"
    end
    unless options[:tags_inverted].nil?
      # map elements to ids
      tags = options[:tags_inverted].to_a.map do |tag|
        (tag.to_i == 0) ? Tag.find_by_name(tag).id : tag.to_i
      end
      tag_inverted_check = "AND (1=1"
      tags.each do |tag_id|
        tag_inverted_check << " AND cached_category_ids NOT LIKE '%;#{tag_id};%' "
      end
      tag_inverted_check << ")"
    end
    # website_name
    if options[:website]
      if options[:website].to_i == 0 # a string
        website_check = " AND sitems.website_id=#{Website.find_by_name(options[:website]).id}"
      else # a number
        website_check = " AND sitems.website_id=#{options[:website]}"
      end
    elsif options[:website_name]
      website_check = " AND sitems.website_id=#{Website.find_by_name(options[:website_name]).id}"
    else
      # website_id
      if options[:website_id]
        website_check = " AND sitems.website_id=#{options[:website_id]} AND sitems.status='Published'" # FIXME: status conflicts with status below?
      end
    end
    # published by
    if options[:published_by]
      users = options[:published_by].to_a.map do |user|
        (user.to_i == 0) ? AdminUser.find_by_username(user).id : user.to_i
      end
      published_by_check = " AND sobjects.updated_by IN (#{users.join(",")})"
    end
    # search_string
    unless options[:search_string].blank?
      search_check = "AND (sitems.name LIKE '%#{ActiveRecord::Base.connection.quote_string(options[:search_string])}%')"
    end
    # content_types
    if options[:content_types]
      # map elements to ids
      ctypes = options[:content_types].to_a.map do |ct|
        (ct.to_i == 0) ? ContentType.find_by_name(ct).id : ct
      end
      content_type_check = " AND sobjects.content_type_id IN (#{ctypes.join(",")})"
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
    # status
    if options[:status]
      options[:status] == :all ?
        status_check = " " :
        status_check = " AND sitems.status='#{options[:status]}'"
    else
      status_check = " AND sitems.status='Published' AND sitems.publish_from<now()" # also check publish_from, we don't want future items if not :all
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
      :limit   => options[:limit]  || 5,
      :offset  => options[:offset] || 0,
      :order   => options[:order]  || "sitems.publish_from DESC"
    )
  end

end
