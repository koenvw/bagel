class LogMessage < ActiveRecord::Base

  SEVERITY = {
    :high   => 1,
    :medium => 2,
    :low    => 3
  }

  SEVERITY_NAMES = SEVERITY.invert

  ROLLOVER = 4.weeks

  belongs_to              :admin_user

  validates_presence_of   :message
  validates_presence_of   :kind
  validates_presence_of   :severity

  validates_inclusion_of  :severity, :in => SEVERITY.values

  def self.log(params={})

    # Extract message
    exception = params[:exception]
    message = params[:message]
    message ||= exception.to_s unless exception.nil?

    # Extract extra info
    extra_info = params[:extra_info] || {}

    # Extract exception
    unless exception.nil?
      extra_info[:exception]          = exception
      extra_info[:function_backtrace] = exception.backtrace unless exception.nil?
      extra_info[:environment]        = ENV.to_hash
    end

    # YAMLize extra info
    begin
      extra_info_text = extra_info.to_yaml
    rescue
      $stderr.puts 'WARNING: Could not YAMLize extra info: ' + extra_info.inspect
      extra_info_text = ''
    end

    # Convert severity
    severity = SEVERITY[params[:severity]]

    # Create log message
    log_message = LogMessage.create :message      => message,
                                    :kind         => params[:kind],
                                    :severity     => severity,
                                    :request_url  => params[:request_url],
                                    :referrer_url => params[:referrer_url],
                                    :extra_info   => extra_info_text

    # Send mail if severity is high
    if params[:severity].to_sym == :high
      LogMailer.deliver_log_message(log_message, params[:hostname] || 'unknown')
    end
  end

  def self.rotate
    LogMessage.delete_all [ 'created_at < ?', Time.now - ROLLOVER]
  end

end
