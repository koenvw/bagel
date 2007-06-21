load 'config/environment.rb'

require 'erb'

class BagelTemplatesVisualiser

  def initialize
    template = File.read('vendor/plugins/bagel/diagram.dot.erb')

    @dot = ERB.new(template).result(binding)
  end

  def output(*filenames)
    filenames.each do |filename|
      format = filename.split('.').last

      if format == 'dot'
        # dot supports -Tdot, but this makes debugging easier :-)
        File.open(filename, 'w') { |io| io << @dot }
        return true
      else
        IO.popen("dot -T#{format} -o #{filename}", 'w') { |io| io << @dot }
        return $?.success?
      end
    end
  end

end
