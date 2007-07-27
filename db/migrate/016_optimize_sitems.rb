class OptimizeSitems < ActiveRecord::Migration
  def self.up
    # Move sitems.name to sobjects.name
    add_column :sobjects, :name, :string
    Sobject.reset_column_information
    Sobject.connection.execute('UPDATE sobjects SET name = (SELECT name FROM sitems WHERE sitems.sobject_id = sobjects.id LIMIT 1)')
    remove_column :sitems, :name

    # Remove sitems.parent_id
    remove_column :sitems, :parent_id

    # Move sitems.link to menus.link
    add_column :menus, :link, :string
    Menu.reset_column_information
    query =  'UPDATE menus SET link = ('
    query <<     'SELECT link FROM sitems WHERE sitems.sobject_id = ('
    query <<         'SELECT id FROM sobjects WHERE content_type = "Menu" AND content_id = menus.id LIMIT 1'
    query <<     ') LIMIT 1'
    query << ')'
    Menu.connection.execute(query)
    remove_column :sitems, :link

    # Move sitems.status to sitems.is_published
    add_column :sitems, :is_published, :boolean
    Sitem.reset_column_information
    Sitem.connection.execute('UPDATE sitems SET is_published = "1" WHERE status = "Published"')
    Sitem.connection.execute('UPDATE sitems SET is_published = "0" WHERE status = "Hidden"')
    remove_column :sitems, :status
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
