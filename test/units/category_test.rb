class CategoryTest < Test::Unit::TestCase
  fixtures :categories
  
  def setup
    @node_with_children     = categories(:node_with_children)
    @child_1                = categories(:child_1)
    @child_2                = categories(:child_2)
    
    @node_without_children  = categories(:node_without_children)
    
    @node_without_parent    = categories(:node_without_parent)
  end
  
  def test_sort_children
    assert_nothing_raised { @node_with_children.sort_children }
    assert_equal          @child_2, @node_with_children.children[0]
    assert_equal          @child_1, @node_with_children.children[1]
  end
  
  def test_sort_no_children
    assert_nothing_raised { @node_without_children.sort_children }
  end
  
  def test_move_left
    assert_nothing_raised { @child_2.move_left }
    assert_equal          @child_2, @node_with_children.children[0]
    assert_equal          @child_1, @node_with_children.children[1]
  end
  
  def test_move_right
    assert_nothing_raised { @child_1.move_right }
    assert_equal          @child_2, @node_with_children.children[0]
    assert_equal          @child_1, @node_with_children.children[1]
  end
  
  def test_move_up
    assert_nothing_raised { @child_1.move_up }
    assert_equal          1, @node_with_children.children.size
    assert_equal          4, @node_with_children.roots.size
    assert                !@child_1.has_parent?
    assert_equal          @child_1, @node_with_children.roots[-1]
  end
  
  def test_move_to_root
    assert_nothing_raised { @child_1.move_to_root }
    assert_equal          1, @node_with_children.children.size
    assert_equal          4, @node_with_children.roots.size
    assert                !@child_1.has_parent?
    assert_equal          @child_1, @node_with_children.roots[-1]
  end
  
  def test_has_children
    assert                !@node_without_children.has_children?
    assert                @node_with_children.has_children?
  end
  
  def test_has_parent
    assert                !@node_without_parent.has_parent?
    assert                @child_1.has_parent?
  end
  
  def test_first
    assert                @child_1.first?
    assert                !@child_2.first?
  end
  
  def test_last
    assert                !@child_1.last?
    assert                @child_2.last?
  end
  
  def test_real_siblings
    assert_equal          1, @child_1.real_siblings.size
    assert_equal          @child_2, @child_1.real_siblings[0]
    assert_equal          2, @node_without_parent.real_siblings.size
  end
  
end
