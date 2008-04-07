# stolen from plugin: http://blog.zvents.com/2006/11/1/rails-plugin-memcacheclient-extensions

class MemCache
  @@server_stats = Hash.new
  cattr_accessor :server_stats

  # The flush_all method empties all cache namespaces on all memcached servers.
  # This method is very useful for testing your code with memcached since
  # you normally  want to reset the cache to a known (empty) state at the
  # beginning of each test.
  def flush_all
    @mutex.lock if @multithread

    raise MemCacheError, "No active servers" unless self.active?

    @servers.each do |server|
      sock = server.socket
      if sock.nil?
        raise MemCacheError, "No connection to server"
      end

      value = nil
      begin
        sock.write "flush_all\r\n"
        text = sock.gets # "OK\r\n"
      rescue SystemCallError, IOError => err
        server.close
        raise MemCacheError, err.message
      end
    end
    ensure
      @mutex.unlock if @multithread
  end
  # stolen from plugin http://agilewebdevelopment.com/plugins/memcache_fragments_with_time_expiry
  def read(key,options=nil)
    begin
      get(key)
    rescue
      ActiveRecord::Base.logger.error("MemCache Error: #{$!}")
    end
  end
  # stolen from plugin http://agilewebdevelopment.com/plugins/memcache_fragments_with_time_expiry
  def write(key,content,options=nil)
    expiry = options && options[:expire] || 0
    begin
      if key =~ %r{^cache_1m_}
        expiry = 1.minutes
      elsif key =~ %r{^cache_5m_}
        expiry = 5.minutes
      elsif key =~ %r{^cache_30m_}
        expiry = 30.minutes
      elsif key =~ %r{^cache_60m_}
        expiry = 60.minutes
      elsif key =~ %r{^cache_2h_}
        expiry = 2.hours
      elsif key =~ %r{^cache_4h_}
        expiry = 4.hours
      elsif key =~ %r{^cache_6h_}
        expiry = 6.hours
      elsif key =~ %r{^cache_8h_}
        expiry = 8.hours
      elsif key =~ %r{^cache_12h_}
        expiry = 12.hours
      elsif key =~ %r{^cache_24h_}
        expiry = 24.hours
      end
      set(key,content,expiry)
    rescue
      ActiveRecord::Base.logger.error("MemCache Error: #{$!}")
    end
  end
end

module ActionView #:nodoc:
  module Helpers #:nodoc:
    module CacheHelper
      # stolen from plugin http://agilewebdevelopment.com/plugins/memcache_fragments_with_time_expiry
      # samples:
      #   <% cache("time",:expire => 1.minute) do %> <%= Time.now %> <% end %>
      #   <% cache("cache_1m_time") do %> <%= Time.now.tomorrow %> <% end %>
      def cache(name = {}, options=nil, &block)
        content = @controller.cache_erb_fragment(block, name, options)

        (options && options[:locals] || {}).each_pair do |key, value|
          content.gsub!(key.to_s, value.to_s)
        end
      end
    end
  end
end

module ActionController::Caching #:nodoc:
  module Fragments
    # modified so that adding "clear=1" to the querystring clears the cache
    def cache_erb_fragment(block, name = {}, options = nil)
      unless perform_caching
        content = block.call
        (options && options[:locals] || {}).each_pair do |key, value|
          content.gsub!(key.to_s, value.to_s)
        end
        return content
      end

      buffer = eval("_erbout", block.binding)

      if params[:clear].nil? && cache = read_fragment(name, options)
        # add cached value to buffer
        buffer.concat(cache)
      else
        # no cache, render block
        pos = buffer.length
        block.call

        write_fragment(name, buffer[pos..-1], options)

        (options && options[:locals] || {}).each_pair do |key, value|
          buffer[pos..-1] = buffer[pos..-1].gsub(key.to_s, value.to_s)
        end
        buffer[pos..-1]
      end
    end
  end
end
