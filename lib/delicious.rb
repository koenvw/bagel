# requirements

begin
  require 'rubygems'
rescue LoadError
end

require 'net/https'
require 'active_support'
require 'rexml/document'

# core extensions

class Time
  def to_iso8601_date
    self.strftime("%Y-%m-%d")
  end

  def to_iso8601_time
    self.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end

class String
  def url_escape
    URI.escape(self, URI::REGEXP::UNSAFE)
  end
end

# del.icio.us stuff

def delicious_post(params={})
  # Extract username and password
  username    = params[:username]
  password    = params[:password]

  # Require username and password
  raise 'No username specified.' if username.blank?
  raise 'No password specified.' if password.blank?

  # Extract post-specific parameters
  url         = params[:url]
  description = params[:description]
  extended    = params[:extended]
  tags        = params[:tags].blank? ? nil : params[:tags].join(' ')
  dt          = params[:dt].blank?   ? nil : params[:dt].to_iso8601_time
  replace     = params.has_key?(:replace) ? (params[:replace] ? 'yes' : 'no') : 'yes'
  shared      = params.has_key?(:shared)  ? (params[:shared]  ? 'yes' : 'no') : 'no'

  # Require parameters
  raise 'No URL specified.' if url.blank?
  raise 'No description specified.' if description.blank?

  # Build request
  request_path = "/v1/posts/add?url=#{url.url_escape}&description=#{description.url_escape}&replace=#{replace}&shared=#{shared}"
  request_path << "&extended=#{extended.url_escape}" unless extended.blank?
  request_path << "&tags=#{tags.url_escape}" unless tags.blank?
  request_path << "&dt=#{dt.url_escape}" unless dt.blank?

  # Connect
  full_success = false
  http = Net::HTTP.new('api.del.icio.us', 443)
  http.use_ssl = true
  http.start do |http|
    request = Net::HTTP::Get.new(request_path)
    request.basic_auth(username, password)

    response = http.request(request)
    if response.kind_of?(Net::HTTPSuccess)
      api_success = REXML::Document.new(response.body).root.attributes['code'] == 'done'
      full_success = api_success
    else
      full_success = false
    end
  end

  full_success
end
