class LogMailer < ActionMailer::Base

  # FIXME send email to all admins instead?
  @@recipient_addresses = [ %( koen.vanwinckel@dotprojects.be ) ]
  cattr_accessor :recipient_addresses

  @@subject_prefix = (Setting.get('EmailSettings') || {})[:subject_prefix] || '[ERROR] '
  cattr_accessor :subject_prefix

  def log_message(log_message, host)
    subject     @@subject_prefix + log_message.message[0..39]

    recipients recipient_addresses
    from       (Setting.get('EmailSettings') || {})[:from_address] || 'Exception Notifier <exception.notifier@default.com>'

    body       :log_message => log_message, :host => host
  end

  def template_root
    "#{File.dirname(__FILE__)}/../views"
  end

end
