class AdminUserTest < Test::Unit::TestCase
  fixtures :admin_users
  
  def test_authenticate
    assert_nil      AdminUser.authenticate('fake_user', 'fake_password')
    assert_nil      AdminUser.authenticate('admin',     'fake_password')
    assert_not_nil  AdminUser.authenticate('admin',     'testing')
    assert_nil      AdminUser.authenticate('kvw',       'fake_password')
    assert_not_nil  AdminUser.authenticate('kvw',       'testing')
  end
end
