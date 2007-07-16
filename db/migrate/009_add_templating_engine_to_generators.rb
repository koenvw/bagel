class AddTemplatingEngineToGenerators < ActiveRecord::Migration
  def self.up
    add_column :generators, :templating_engine, :string
  end

  def self.down
    remove_column :generators, :templating_engine
  end
end
