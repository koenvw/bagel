require 'erb'

module Algorithm # :nodoc:
  module Diff
    def self.ond(list_a,list_b)
      m = list_a.size
      n = list_b.size
      delta = m - n
      ofs = max = m + n
      v = Array.new(max * 2 + 2, 0)
      snake = Hash.new()
      nn = Array.new(max+1)
      d = 0
      nextbest = 0
      while (d <= max)
        work = Array.new(n+1)
        nn[d] = work
        k = -d
        best = nextbest
        while (k <= d) 
          if ((k + delta).abs > max - best)
            k+=2
            next
          end
          a = v[k - 1 + ofs]
          b = v[k + 1 + ofs]
          y = ( (k == -d) || (k != d) && (a < b)) ? b : a + 1
          x = y - k
          count = 0
          while ( x < m && y < n && list_a[x] == list_b[y])
            x += 1
            y += 1
            count+= 1
          end
          p = work[y]
          if (p == nil)
            work[y] = p = [x]
          else
            work[y] = (p << x)
          end
          if (count > 0) then
            s = snake[idx = x + y * m]
            s = 0 if s == nil
            if (x >= 0 && s < count)
              snake[idx] = count
            end
          end
          v[k + ofs] = y 
          if (x == m && y == n)
            return [d,snake,nn]
          end
          k += 2
          nextbest = ((pos = x+y) > nextbest) ? pos : nextbest
        end
        d += 1
      end
      return nil
    end
    
    def self.solve(a,b,d,snake,nn)
      path = []
      m = a.size
      n = b.size
      d = d - 1
      x = m
      y = n
      path << [x,y]
      mx = -1
      my = -1
      p = nil
      s = nil
      while d >= 0
        p = nn[d]
        s = snake[x + y * m]
        s = 0 if s == nil
        px = x - s
        py = y - s
        mx = -1
        my = -1
        if (((q = p[py-1]) != nil) && q.index(px) != nil)
          mx = px
          my = py - 1
          path << [px, py]
        elsif (((q = p[py]) != nil) && q.index(px - 1) != nil)
          mx = px - 1
          my = py
          path << [px, py]
        elsif (((q = p[py]) != nil) && q.index(px) != nil)
          mx = px
          my = py;
        end
        path << [mx, my]
        x = mx
        y = my
        break if (x == 0 && y == 0)
        d -= 1
      end
      path << [0, 0]
      path = path.reverse
      if (path[1] == [0,0])
        path.shift
      end
      path
    end
    
    def self.diff(list_a,list_b,path)
      hunk_list = []
      hunk = []
      (0..path.size-2).each {|i|
        x,y = path[i]
        mx,my = path[i+1]
        if x == mx
          while y < my
            hunk << [ '+', y, list_b[y]]
            y += 1
          end
        elsif y == my
          while (x < mx)
            hunk << [ '-', x, list_a[x]]
            x += 1
          end
        else
          hunk_list << hunk
          hunk = []
        end
      }
      unless hunk.empty?
        hunk_list << hunk
      end
      return hunk_list
    end
    
    def self.sdiff(list_a,list_b,path)
      hunk_list = []
      hunk = []
      (0..path.size-2).each {|i|
        x,y = path[i]
        mx,my = path[i+1]
        if x == mx
          while y < my
            hunk << [ '+', nil, list_b[y] ]
            y += 1
          end
        elsif y == my
          while (x < mx)
            hunk << [ '-', list_a[x], nil ]
            x += 1
          end
        else
          hunk_list << hunk
          while (x < mx && y < my)
            hunk_list << ['u', list_a[x], list_b[y]]
            x += 1
            y += 1
          end
          hunk = []
        end
      }
      unless hunk.empty?
        hunk_list << hunk
      end
      
      list = []
      hunk_list.each {|hunk|
        if hunk.first=='u'
          list << hunk
        elsif hunk.size==1
          list << hunk.first
        else
          del_idx = 0
          while del_idx < hunk.size
            break if hunk[del_idx].first=='-'
            del_idx += 1
          end
          ins_idx = 0
          while ins_idx < hunk.size
            break if hunk[ins_idx].first=='+'
            ins_idx += 1
          end
          while del_idx < hunk.size || ins_idx < hunk.size
            del = nil
            ins = nil
            if del_idx < hunk.size
              del = hunk[del_idx][1]
            end
            if ins_idx < hunk.size
              ins = hunk[ins_idx][2]
            end
            if del && ins
              list << ['c',del,ins]
            elsif del
              list << ['-',del,nil]
            elsif ins
              list << ['+',nil,ins]
            end
            del_idx += 1
            ins_idx += 1
          end
        end
      }
      list
    end
    
    def self.traverse(list_a,list_b,path,obj)
      (0..path.size-2).each {|i|
        x,y = path[i]
        mx,my = path[i+1]
        if x == mx
          while y < my
            obj.discard_b(mx, y, list_b[y])
            y += 1
          end
        elsif y == my
          while (x < mx)
            obj.discard_a(x, my, list_a[x])
            x += 1
          end
        else
          while (x < mx && y < my)
            obj.match(x, y, list_b[y])
            x += 1
            y += 1
          end
        end
      }
      return
    end
    
    
  end
end

class String
  # Returns an array of hashes. Each hash has a :text key and a :type key.
  # The type key can be :added, :removed or :kept
  def line_diff_with(other)
    a =  self.split(/\n/).map { |l| l.sub(/[\r\n]$/, '') }
    b = other.split(/\n/).map { |l| l.sub(/[\r\n]$/, '') }
    d,snake,nn = Algorithm::Diff.ond(a,b)
    if d
      path = Algorithm::Diff.solve(a,b,d,snake,nn)
      o = StringDiff.new
      Algorithm::Diff.traverse(a,b,path,o)
      o.arr
    end
  end

  def text_diff_with(other)
    self.line_diff_with(other).inject('') do |memo, hash|
      case hash[:type]
      when :added
        symbol = '+'
      when :removed
        symbol = '-'
      else
        symbol = ' '
      end
      
      memo + %[#{symbol} #{hash[:text]}\n]
    end
  end

  def html_diff_with(other)
    '<pre><code>' + self.line_diff_with(other).inject('') do |memo, hash|
      case hash[:type]
      when :added
        color = '#cfc'
      when :removed
        color = '#fcc'
      else
        color = '#fff'
      end
      
      memo + %[<span style="background-color:#{color}">#{ERB::Util.h hash[:text]}</span>\n]
    end + '</code></pre>'
  end
end

class StringDiff # :nodoc:
  def initialize
    @arr = []
  end

  def discard_a(i, j, v)
    @arr << { :text => v, :type => :removed }
  end

  def discard_b(i, j, v)
    @arr << { :text => v, :type => :added }
  end

  def match(i, j, v)
    @arr << { :text => v, :type => :kept }
  end

  def arr
    @arr
  end
end
