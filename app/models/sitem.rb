class Sitem < ActiveRecord::Base

  belongs_to :website
  belongs_to :sobject
  belongs_to :content, :polymorphic => true

  # Compatibility

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

end
