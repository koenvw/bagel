class Sobject < ActiveRecord::Base
  belongs_to :content, :polymorphic => true
  #FIXME: need to add new content_types here
  # also ... where is this used ?
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
  # content_type
  belongs_to :ctype, :foreign_key => "content_type_id", :class_name => "ContentType"
  # "tags"
  has_and_belongs_to_many :tags, :after_add => :update_cached_tags, :after_remove => :update_cached_tags,
                          :join_table => "categories_sobjects", :association_foreign_key => "category_id"
                          #FIXME: rename category_sobjects to tags_sobjects
  has_many :sitems
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
    # website_name, website_id, content_types, tag_names, limit=5, offset=0, search_string=nil,publish_from=nil,publish_till=nil,order="sitems.publish_from DESC",status="Published"
    # tags
    unless options[:tag_names].nil?
      tag_check = "AND (1=0"
      options[:tag_names].each do |tag|
        tag_check << " OR cached_category_ids LIKE '%;#{Tag.find_by_name(tag).id};%' "
      end
      #FIXME: these are exceptions because they don't have a tag (better exclude tags than include them ??)
      tag_check << " OR sobjects.content_type ='TestArticle'"
      tag_check << " OR sobjects.content_type ='Book')"
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
      else
        website_check = ""
      end
    end
    # search_string
    # FIXME: sql injection!!
    if options[:search_string] and options[:search_string].size > 0
      search_check = "AND (sitems.name LIKE '%#{options[:search_string]}%')"
    else
      search_check = ""
    end
    # content_types
    if options[:content_types]
      if options[:content_types].is_a?(Array)
        # map elements to ids
        ctypes = options[:content_types].map do |ct|
          (ct.to_i == 0) ? ContentType.find_by_name(ct).id : ct
        end
      else
        if options[:content_types].to_i == 0
          ctypes = [ContentType.find_by_name(options[:content_types]).id]
        else
          ctypes = [options[:content_types]]
        end
      end
      content_type_check = " AND sobjects.content_type_id IN (#{ctypes.join(",")})"
    end
    # publish_from
    if options[:publish_from]
      publish_from_check = " AND sitems.publish_from > '#{options[:publish_from].to_time.localize("%Y-%m-%d %H:%I:%S")}'"
    elsif options[:status] != :all
      publish_from_check = " AND sitems.publish_from<now()"
    else
      publish_from_check = " AND sitems.publish_from>'0001-01-01'"
    end
    # publish_till
    if options[:publish_till]
      publish_till_check = " AND sitems.publish_from < '#{options[:publish_till].to_time.localize("%Y-%m-%d %H:%I:%S")}'"
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
        #{search_check}
        #{content_type_check}
        #{publish_from_check}
        #{publish_till_check}
        #{options[:conditions]}
      ",
      :include => includes,
      :limit   => options[:limit]  || 5,
      :offset  => options[:offset] || 0,
      :order   => options[:order]  || "sitems.publish_from DESC"
    )
  end

end
