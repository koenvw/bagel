class Sitem < ActiveRecord::Base

  belongs_to :website
  belongs_to :sobject
  belongs_to :content, :polymorphic => true

  def published?
    if sobject.inverse_translation_relations.empty?
      sync = sobject.publish_synced?
    else
      sync = sobject.inverse_translation_relations.first.from.publish_synced?
    end
    
    if sync
      published_sync?
    else
      published_async?
    end
  end

  def published_sync?
    if sobject.translation_relations.empty?
      sobject.inverse_translation_relations.map(&:from).all? { |so| so.published_async? }
    else
      sobject.translation_relations.map(&:to).all?           { |so| so.published_async? }
    end
  end
  
  def published_async?
    self[:is_published]
  end

  # Deprecated

  def status
    $stderr.puts('DEPRECATION WARNING: Sitem#status is deprecated; use Sitem#is_published? instead')
    is_published?
  end

  def status=(status)
    $stderr.puts('DEPRECATION WARNING: Sitem#status= is deprecated; use Sitem#is_published= instead')
    is_published = (status == 'Published' or status == '1' ? true : false)
  end

  def link
    $stderr.puts('DEPRECATION WARNING: Sitem#link is deprecated; use Menu#link instead')
    sobject.menu.link
  end

  def link=(link)
    $stderr.puts('DEPRECATION WARNING: Sitem#link= is deprecated; use Menu#link= instead')
    sobject.menu.link = link
  end

  def name
    $stderr.puts('DEPRECATION WARNING: Sitem#name is deprecated; use Sobject#name instead')
    sobject.name
  end

  def name=(name)
    $stderr.puts('DEPRECATION WARNING: Sitem#name= is deprecated; use Sobject#name= instead')
    sobject.name = name
  end

  def is_published?
    published?
  end

end
