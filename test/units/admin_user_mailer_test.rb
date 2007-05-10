class AdminUserMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  fixtures :admin_users

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end

  def test_password_reset
    @expected.from    = "bagel@dotprojects.be"
    @expected.subject = 'Resetting your Bagel password'
    @expected.body    = read_fixture('password_reset')
    @expected.date    = Time.now

    assert_equal @expected.encoded, AdminUserMailer.create_password_reset(admin_users(:admin)).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/admin_user_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
