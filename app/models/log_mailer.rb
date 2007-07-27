class LogMailer < ActionMailer::Base

  # FIXME send email to all admins instead?
  @@recipient_addresses = [ %( "Denis Defreyne" <denis.defreyne@stoneship.org> ) ]
  cattr_accessor :recipient_addresses

  @@subject_prefix = "[ERROR] "
  cattr_accessor :subject_prefix

  def log_message(log_message, host)
    subject     @@subject_prefix + 'New log message: ' + log_message.message[0..39]

    recipients recipient_addresses
    from       (Setting.get('EmailSettings') || {})[:address] || 'noemail@example.com'

    body       :log_message => log_message, :host => host
  end

  def template_root
    "#{File.dirname(__FILE__)}/../views"
  end

end
