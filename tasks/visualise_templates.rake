# =============================================================================
# A rake task to generate dependency graphs of your Bagel templates
# =============================================================================

desc "Create a diagram of your Bagel templates"
namespace :bagel do
  namespace :util do
    task :visualise_templates => :environment do
      load RAILS_ROOT + '/vendor/plugins/bagel/lib/bagel_templates_visualiser.rb'

      filename = ENV['FILENAME'] || 'doc/templates_dependencies.png'

      btv = BagelTemplatesVisualiser.new

      if btv.output(filename)
        puts "Generated #{filename}."
      else
        btv.output "btv-debug.dot"
        puts "Error! Please file a bug report with 'btv-debug.dot' attached."
      end
    end
  end
end
