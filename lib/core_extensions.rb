class String
  def nil_or_empty?
    empty?
  end
  def clean
    downcase.strip.gsub(/[^-_\s[:alnum:]]/, '').tr(' ', '_')
  end
  def rubify
    downcase.strip.gsub(/[^-_\s[:alnum:]]/, '').squeeze(' ').tr(' ', '_')
  end
  def rubify!
    replace rubify
  end
  def domainify
    str = gsub(".","_").gsub(":","-").gsub("www_","")
    return str.gsub("fr_autovibes_be","autovibes_fr").gsub("fr_auto55_be","auto55_fr").gsub("auto55_com","auto55_be").gsub("fr_auto55_com","auto55_fr")
  end
  #FIXME:
  def t
    to_s
  end
end
class Time
  def formatted
    strftime("%d %b %Y").strip
  end
  def format_out
    $stderr.puts('DEPRECATION WARNING: format_out is deprecated. use formatted()')
    formatted
  end
end
class Float
  def round_to(x)
    (self * 10**x).round.to_f / 10**x
  end

  def ceil_to(x)
    (self * 10**x).ceil.to_f / 10**x
  end

  def floor_to(x)
    (self * 10**x).floor.to_f / 10**x
  end
end
class Array
  # checks every element for nil.
  # if an element is an array, it is only considered nil if all elements are nil
  def has_nilelement?
    select { |element| 
      element.is_a?(Array) ? element.select {|el| el.nil? }.size == element.size : element.nil? 
    }.size > 0
  end
end
class NilClass
  def nil_or_empty?
    true
  end
end
