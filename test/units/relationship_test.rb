require File.dirname(__FILE__) + '/../test_helper'

class RelationshipTest < Test::Unit::TestCase
  fixtures :relationships

  def setup
    @relation = Relationship.find(1)
  end

  def test_validation_presence
    rel = Relationship.new
    assert_equal false,rel.save
    assert_not_nil rel.errors["category"]
    assert_not_nil rel.errors["from"]
    assert_not_nil rel.errors["to"]
  end

  def test_validation_unique
    rel = Relationship.new
    rel.from_sobject_id = 1
    rel.to_sobject_id = 1
    rel.category_id = 1
    # must clash with fixture
    rel.save
    assert_equal false,rel.save
    assert_not_nil rel.errors["category_id"]

  end
end
