class News < ActiveRecord::Base
  acts_as_content_type
  acts_as_ferret :fields => [ :title, :body ], :remote => AppConfig[:use_ferret_server]

  validates_presence_of :title
  validates_presence_of :body

  def prepare_sitem
    sitems.each do |sitem|
      sitem.name = title unless title.nil?
    end
  end

  ### DEPRECATED ###

  def self.find_with_website(site, *args)
    $stderr.puts('DEPRECATION WARNING: News.find_with_website is deprecated; please use Sobject.find_with_parameters')
    args[0][:joins] = "INNER JOIN sitems ON sitems.content_id=id"
    find(:all, args)
  end

  def self.recent(site, type, limit=5, offset=0, popular=0,only_with_relation="")
    $stderr.puts('DEPRECATION WARNING: News.find_with_website is deprecated; please use Sobject.find_with_parameters')
    category = Tag.find_by_name(type)
    unless category.nil?
      if popular==1
        xorder="sitems.click_count DESC,"
        #xorder="((TO_DAYS(sitems.publish_from)-TO_DAYS(NOW()))/sitems.click_count) DESC,"
        xsql="AND sitems.publish_from>DATE_SUB(now(), INTERVAL 30 DAY)"
      else
        xorder = ""
      end
      if only_with_relation.size > 0
        # use this if you only want news that has a certain relation (eg.: "Picture")
        relation_category = Relation.find_by_name(only_with_relation)
        xrels = " INNER JOIN relationships ON relationships.category_id = #{relation_category.id} AND relationships.from_sobject_id = sobjects.id"
      else
        xrels = ""
      end
      website_id = AppConfig[:websites][site]
      website_id = Website.find_by_name(site).id if website_id.nil?
      find(
        :all,
        :order => xorder + "sitems.publish_from DESC",
        :conditions=>["
          news.title<>''
          AND sitems.website_id=#{website_id}
          AND (sitems.publish_till<now() OR sitems.publish_till IS NULL)
          AND sitems.publish_from<now()
          AND sitems.status='Published'
        ",xsql],
        :offset=> offset,
        :limit=> limit,
        :include=>[:sobject,:sitems],
        :joins => ["INNER JOIN categories_sobjects CA ON CA.category_id = #{category.id} AND sobjects.id = CA.sobject_id",xrels]
       )
    end
  end


end
