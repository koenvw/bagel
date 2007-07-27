require 'string_diff'

class Object
  def inspect_with_newlines(indent=0)
    inspect
  end
end

class String
  def inspect_with_newlines(indent=0)
    space      = ' ' * (indent*4)
    space_more = ' ' * ((indent+1)*4)

    res = "\"\n"
    lines = gsub('</p>', "</p>\n").split(/\n/)
    lines.each { |l| res << space_more + l + "\n" }
    res << space + "\""

    res
  end
end

class Array
  def inspect_with_newlines(indent=0)
    space      = ' ' * (indent*4)
    space_more = ' ' * ((indent+1)*4)

    res = ''

    res << "[\n"
    each { |item| res << space_more + item.inspect_with_newlines(indent+1) + ",\n" }
    res << space + "]"
    res
  end
end

class Hash
  def inspect_with_newlines(indent=0)
    space      = ' ' * (indent*4)
    space_more = ' ' * ((indent+1)*4)

    res = ''

    sorted_hash = []
    each_pair { |key, value| sorted_hash << { key => value } }
    sorted_hash.sort! { |x, y| x.keys.first.to_s <=> y.keys.first.to_s }

    res << "{\n"
    sorted_hash.each do |item|
      key = item.keys.first
      value = item.values.first
      res << space_more + key.inspect + ' => ' + value.inspect_with_newlines(indent+1) + ",\n"
    end
    res << space + "}"
    res
  end
end

# Two big sample hashes, for testing:
# 
# one = ({ :foo => :bar, :moo => "asdf\nfdsa\nfawefweafawefa wef aw f\nasfaev", :baz => :quux, :xxx => :yyy, :zzz => [ :asdf, :xxx, :yyy, { :zzz => :asdfsdf, :asdfs => :fdsaf, :x => { :y => { :z => { :t => 0, :p => [ 0, [ 1, 2, 3, 4, [ 3, 4, { :x => :z, :foo => :bar, :moo => :meow, :bark => :woof }], [5] ]] }}} } ] })
# 
# two = ({ :foo => :bar, :baz => :quux, :xxx => :asdf, :asdff => [ :asdf, :xxx, :yyy, { :zzz => :asdfsdf, :asdfs => :fdsaf, :xx => { :y => { :z => { :t => 0, :p => [ 0, [ 1, 2, 35, 4, [ 3, 4, { :x => :z, :foo => :bar, :moo => :meow, :bark => :woof }], [5, 7, 8] ]] }}} } ] })
