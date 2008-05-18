class MakeMultiSiteOptional < ActiveRecord::Migration
  def self.up
    # update schema
    add_column :sobjects, :website_id,        :integer
    add_column :sobjects, :publish_from,      :datetime
    add_column :sobjects, :publish_till,      :datetime
    add_column :sobjects, :publish_date,      :datetime
    add_column :sobjects, :is_published,      :boolean
    add_column :sitems,   :is_default,        :boolean
    #
    add_index :sobjects, :publish_from
    add_index :sobjects, :publish_till
    add_index :sobjects, :content_type_id

    # migrate data
    Sobject.find(:all, :include => :sitems).each do |sobject|
      if sobject.sitems.size > 0
        first_sitem = sobject.sitems.first # yea i know.
        [:website_id, :publish_from, :publish_till, :publish_date, :is_published].each do |property|
          sobject.send("#{property}=",first_sitem.send(property))
        end
        sobject.save
      end
    end
  end

  def self.down
    remove_column :sobjects, :website_id
    remove_column :sobjects, :publish_from
    remove_column :sobjects, :publish_till
    remove_column :sobjects, :publish_date
    remove_column :sobjects, :is_published
  end
end
