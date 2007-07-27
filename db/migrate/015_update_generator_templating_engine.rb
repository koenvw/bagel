class UpdateGeneratorTemplatingEngine < ActiveRecord::Migration
  def self.up
    Generator.update_all('templating_engine = "erb"', 'templating_engine IS NULL')
  end

  def self.down
  end
end
