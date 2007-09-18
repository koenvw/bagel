class String
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
    gsub(".","_").gsub(":","-").gsub("www_","")
  end

  def to_bool
    return true if to_s.downcase == "true"
    return false if to_s.downcase == "false"
  end

  def disable_html
    self.gsub(/<input/,    '<input readonly="readonly"').
         gsub(/<textarea/, '<textarea readonly="readonly"')
  end
end

class Time
  def formatted
    strftime("%d %b %Y").strip
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
    any? { |e|e.respond_to?(:all?) ? e.all? { |x| x.nil? } : e.nil? }
  end

  def each_with_level # used in combination with convert_to_tree helper
    each { |tuple| yield(tuple[:item], tuple[:level]) }
  end

  def to_tree
    hash = {} # id => level
    res  = [] # item => level

    each do |item|
      level = hash.has_key?(item.parent_id) ? hash[item.parent_id] + 1 : 0
      hash[item.id] = level
      res << { :item => item, :level =>level }
    end

    res
  end
end

# Converting hashes/arrays/... to HTML

require 'erb' # For ERB:Util.h

def true.to_html  ; 'true'   ; end
def false.to_html ; 'false'  ; end
def nil.to_html   ; '(null)' ; end

class String
  def to_html
    self
  end
end

class Hash
  def to_html
    res = '<dl>'
    each_pair do |key, value|
      res << '<dt>' + (key.respond_to?(:to_html)   ? key.to_html   : ERB::Util.h(key.to_s)) + '</dt>'
      res << '<dd>' + (value.respond_to?(:to_html) ? value.to_html : ERB::Util.h(value.to_s)) + '</dd>'
    end
    res << '</dl>'
  end
end

class Array
  def to_html
    res = '<ol>'
    each do |item|
      res << '<li>' + (item.respond_to?(:to_html) ? item.to_html : ERB::Util.h(item.to_s))  + '</li>'
    end
    res << '</ol>'
  end
end

# Deprecated

class NilClass
  def nil_or_empty?
    $stderr.puts('DEPRECATION WARNING: nil_or_empty? is deprecated. use blank?')
    true
  end
end

class Array
  def nil_or_empty?
    $stderr.puts('DEPRECATION WARNING: nil_or_empty? is deprecated. use blank?')
    empty?
  end
end

class String
  def nil_or_empty?
    $stderr.puts('DEPRECATION WARNING: nil_or_empty? is deprecated. use blank?')
    empty?
  end
end

class Time
  def format_out
    $stderr.puts('DEPRECATION WARNING: format_out is deprecated. use formatted()')
    formatted
  end
end
