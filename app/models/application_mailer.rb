class ApplicationMailer < ActionMailer::Base

  def template_mail(options, sent_at = Time.now)

    # write static version
    unless options[:write_static].nil?
      file_path = RAILS_ROOT + "/public/#{options[:write_static]}.html"
      unless File.exists?(file_path)
        FileUtils.mkdir_p File.dirname(file_path) unless File.exists?(File.dirname(file_path))
        options_backup = options.dup
        options_backup[:form].delete(:email)
        @controller = ActionController::Base.new
        @body = initialize_template_class(:data => options_backup[:form]).render(:inline => options[:body])
        File.open("#{file_path}", "w") do |file|
            file << @body
        end
      end
    end

    @body = initialize_template_class(:data => options[:form]).render(:inline => options[:body])
    @content_type = options[:content_type] || "text/html"
    @charset    = options[:charset] || "ISO-8859-1"
    @subject    = options[:subject]
    @recipients = options[:to]
    @from       = options[:from]
    @bcc        = options[:bcc]
    @sent_on    = sent_at
    @headers    = {}
    logger.info "template_mail: to: #{options[:to]}, from: #{options[:from]}, subject:#{options[:subject]}"

  end

  def receive(email)
    return unless email.content_type == "multipart/report"
    bounce = BouncedDelivery.from_email(email)
    msg = MailDelivery.find_by_message_id(bounce.original_message_id)
    if msg.nil?
      logger.warn "--BOUNCHECKER:id:#{bounce.original_message_id}:NOTFOUND::email:#{bounce.to_email_adres}"
      return false
    else
      logger.info "--BOUNCECHECKER:id:#{bounce.original_message_id}:FOUND::email:#{bounce.to_email_adres}"
      return msg.update_attribute(:status, bounce.status)
    end
  end

  # FIXME: not used ?
  def cache_erb_fragment(block, name = {}, options = nil)
    unless AppConfig[:perform_caching] then block.call; return end
    buffer = eval("_erbout", block.binding)
    if cache = Cache.get(name)
      buffer.concat(cache)
    else
      pos = buffer.length
      block.call
      Cache.put(name, buffer[pos..-1], 600)
    end
  end

  # FIXME: not used ?
  def initialize_template_class(assigns)
    ActionView::Base.new(template_path, assigns, self)
  end

end

class BouncedDelivery
  attr_accessor :status_info, :original_message_id, :to_email_adres

  def self.from_email(email)
    returning(bounce = self.new) do
      status_part = email.parts.detect do |part|
        part.content_type == "message/delivery-status"
      end
      unless status_part.nil?
        statuses = status_part.body.split(/\n/)
        bounce.status_info = statuses.inject({}) do |hash, line|
          key, value = line.split(/:/)
          hash[key] = value.strip rescue nil
          hash
        end
        original_message_part = email.parts.detect do |part|
          part.content_type == "message/rfc822"
        end
        unless original_message_part.nil?
          parsed_msg = TMail::Mail.parse(original_message_part.body)
          bounce.to_email_adres = parsed_msg.to
          bounce.original_message_id = parsed_msg.message_id
        end
      end
    end
  end

  def status
    case status_info['Status']
    when /^5/
      'Failure'
    when /^4/
      'Temporary Failure'
    when /^2/
      'Success'
    end
 end
end
