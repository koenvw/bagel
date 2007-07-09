class AdminUserMailer < ActionMailer::Base #:nodoc:

  def password_reset(a_admin_user, host)
    default_url_options[:host] = host
    
    @subject    = 'Resetting your Bagel password'
    @body       = { :admin_user => a_admin_user }
    @recipients = a_admin_user.email_address
    @from       = Setting.get('EmailSettings')[:address] || 'noemail@example.com'
    @sent_on    = Time.now
  end

  def email_change_confirmation(a_admin_user, host)
    default_url_options[:host] = host
    
    @subject    = 'Confirming your Bagel e-mail address change'
    @body       = { :admin_user => a_admin_user }
    @recipients = a_admin_user.email_address_unconfirmed
    @from       = Setting.get('EmailSettings')[:address] || 'noemail@example.com'
    @sent_on    = Time.now
  end

end
