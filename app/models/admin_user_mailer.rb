class AdminUserMailer < ActionMailer::Base #:nodoc:

  # FIXME: Determine host based on request
  default_url_options[:host] = 'localhost:3000'

  def password_reset(a_admin_user)
    @subject    = 'Resetting your Bagel password'
    @body       = { :admin_user => a_admin_user }
    @recipients = a_admin_user.email_address
    # FIXME: Store sender e-mail address somewhere globally
    @from       = 'bagel@dotprojects.be'
    @sent_on    = Time.now
  end
  
  def email_change_confirmation(a_admin_user)
    @subject    = 'Confirming your Bagel e-mail address change'
    @body       = { :admin_user => a_admin_user }
    @recipients = a_admin_user.email_address_unconfirmed
    # FIXME: Store sender e-mail address somewhere globally
    @from       = 'bagel@dotprojects.be'
    @sent_on    = Time.now
  end
  
end
