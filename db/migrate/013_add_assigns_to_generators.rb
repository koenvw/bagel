class AddAssignsToGenerators < ActiveRecord::Migration
  def self.up
    # This is probably temporary... it contains code which will return a Ruby hash
    # which will then be passed to Liquid as assigns
    add_column :generators, :assigns, :text
  end

  def self.down
    remove_column :generators, :assigns
  end
end
