require 'net/pop'
class QueuedMail < ActiveRecord::Base
  #background :deliver, :every => 1.minute, :concurrent => true

  serialize :object

  def self.deliver
    MailQueue.process
  end


  def self.generate(website_name,to_email=nil)
    # loop each child (=website) of "newsletters"-settings
    Setting.get_cached("Newsletters").each do |letter_name,letter_settings|
      website = Website.find_by_name(letter_name.to_s)
      # only process given website
      next if website.nil? or website.name != website_name
      generator_name = letter_settings[:generator]
      from = letter_settings[:from]
      subject = letter_settings[:subject]
      counter = letter_settings[:counter]
      updated_on = letter_settings[:updated_on]
      generator = Generator.find_by_name(generator_name)
      time = Time.now

      next if [website,generator_name,from,subject,generator].has_nilelement?

      # fill data
      data = {}
      data[:static_url] = "newsletters/" + website_name + "/" + time.strftime("%Y%m%d")
      data[:date] = time.formatted
      data[:counter] = counter
      data[:updated_on] = updated_on

      if to_email.nil?
    siteusers = SiteUser.find_with_website_id(website.id)
      else
    if to_email.is_a?(String)
      siteusers = SiteUser.find_all_by_email(to_email)
    else
      siteusers = to_email.map {|email| SiteUser.find_by_email(email) }
      siteusers = siteusers.select {|siteuser| !siteuser.nil?}
    end
      end
      puts "Mailing: #{siteusers.size} site_users"
      siteusers.each do |siteuser|
        params = {}
        params[:from] = from
        params[:to] = siteuser.email
        params[:subject] = subject
        params[:siteuser] = siteuser
        params[:body] = generator.template
        params[:write_static] = data[:static_url]
        params[:form] = data
        params[:form][:email] = siteuser.email
        params[:charset] = "UTF-8"
        puts siteuser.email
        mail = ApplicationMailer.deliver_template_mail(params)
        MailDelivery.create(:message_id => mail.message_id, :recipient => params[:to], :site_user_id => siteuser.id, :content => "", :status => 'Sent' )
      end

      # don't update setting if this was a testmailing
      return unless to_email.nil?
      # update counter
      counter_setting = Setting.find_by_name("Newsletters").children.find_by_name(letter_name.to_s).children.find_by_name("counter")
      unless counter_setting.nil?
        counter_setting.value = (counter_setting.value.to_i + 1).to_s
      counter_setting.save
      end
      # update updated_on
      updated_on_setting = Setting.find_by_name("Newsletters").children.find_by_name(letter_name.to_s).children.find_by_name("updated_on")
      unless updated_on_setting.nil?
        updated_on_setting.value = Time.now.strftime("%Y-%m-%d %H:%I:%S")
        updated_on_setting.save
      end
    end
  end

  def self.read_mail
    # get settings
    settings = Setting.get_cached("bounce_checker")
    return if settings.nil?
    hostname = settings[:pop3_hostname]
    username = settings[:pop3_username]
    password = settings[:pop3_password]
    return if [hostname,username,password].has_nilelement?
    # pop tha box!
    Net::POP3.start(hostname, nil, username, password) do |pop|
      puts "mails:#{pop.mails.size}"
      unless pop.mails.empty?
        pop.mails.each do |email|
          if ApplicationMailer.receive(email.pop)
            email.delete
          else
            # message stays on server
          end
        end
      end
    end
    # clean up mail deliveries
    MailDelivery.destroy_all "created_on < date_sub(now(), interval 7 day) AND status = 'Sent'"
    # deactivate site_users
    maildeliveries = MailDelivery.find_by_sql("SELECT distinct(site_user_id) site_user_id, count(*) count FROM `mail_deliveries` WHERE status='failure' GROUP BY site_user_id HAVING count > 4")
    bounced = Tag.find_by_name("Bounced")
    bounced = Tag.create :name => "Bounced" if bounced.nil?
    maildeliveries.each do |md|
      if SiteUser.exists?(md.site_user_id)
        su = SiteUser.find(md.site_user_id)
        su.active = false
        su.add_tag_unless bounced
        su.save
        MailDelivery.destroy_all "site_user_id = #{md.site_user_id}"
      end
    end
  end

end
