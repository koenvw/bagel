class Admin::MeController < ApplicationController
  def show
  end

  def edit
    @admin_user = AdminUser.current_user
  end

  def update
    @admin_user = AdminUser.current_user

    # Prevent some details from being updated
    params[:admin_user].delete(:admin_role_ids)

    if @admin_user.update_attributes(params[:admin_user])
      # Check password
      if not params[:password].nil? and params[:password] != params[:password_confirmation]
        flash[:warning] = 'The passwords you provided do not match. Please try again.'
        render :action => 'edit' and return
      end

      # Save password
      @admin_user.password = params[:password] unless params[:password].nil_or_empty?
      @admin_user.save

      # Handle e-mail address change
      # TODO let e-mail address changes time out after... 3 hours or so
      if not params[:email_address].blank? and @admin_user.email_address != params[:email_address]
        # Create an email address code
        chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        email_address_code = ''
        20.times { email_address_code << chars[rand(chars.size-1)] }
        @admin_user.email_address_code = email_address_code
        @admin_user.save

        # Send confirmation mail
        @admin_user.email_address_unconfirmed = params[:email_address]
        @admin_user.save
        AdminUserMailer.deliver_email_change_confirmation(@admin_user)

        flash[:notice] = 'Your settings have been updated successfully, and an e-mail address change confirmation mail has been sent.'
      else
        flash[:notice] = 'Your settings have been updated successfully.'
      end

      redirect_to admin_me_url
    else
      render :action => 'edit'
    end
  end

  def change_email_address
    user = AdminUser.current_user

    # Get codes
    given_code  = params[:code]
    stored_code = user.email_address_code

    # Compare codes
    if given_code.nil? or given_code != stored_code
      flash[:error] = 'The given e-mail address code is not valid, or you used a code that has already been used.'
      redirect_to admin_me_url
      return
    end

    if request.post?
      # Change e-mail address
      user.email_address = user.email_address_unconfirmed
      user.email_address_unconfirmed = nil
      user.email_address_code = nil
      user.save

      # Done
      flash[:notice] = 'Your e-mail address has been changed.'
      redirect_to admin_me_url
    else
      render
    end
  end
end
