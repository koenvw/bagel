module ActsAsEnhancedNestedSet

  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end

  module ClassMethods

    def acts_as_enhanced_nested_set(options = {})
      acts_as_nested_set options
      class_eval do
        include InstanceMethods
      end
    end

    # TODO: remove me
    def move_left(id)
      $stderr.puts 'DEPRECATION WARNING: ActsAsEnhancedNestedSet.move_left() is deprecated; use the instance method instead.'

      # Find node
      moving_node = self.find(id)
      return if moving_node.blank?

      # Move node right
      moving_node.move_left
    end

    # TODO: remove me
    def move_right(id)
      $stderr.puts 'DEPRECATION WARNING: ActsAsEnhancedNestedSet.move_right() is deprecated; use the instance method instead.'

      # Find node
      moving_node = self.find(id)
      return if moving_node.blank?

      # Move node right
      moving_node.move_right
    end

    def sort_all(sorted_list)
      #FIXME:
    end

  end

  module InstanceMethods

    def to_child_of(target)
      if target.blank? || target.to_s == "0"
        move_to_root
      else
        move_to_child_of(target)
      end
    end

    def move_left
      # Find the largest of all smaller siblings
      smaller_siblings = real_siblings.select { |node| node.attributes[self.right_col_name] < self.attributes[self.right_col_name] }
      return if smaller_siblings.blank?
      largest_smaller_sibling = smaller_siblings.max { |x,y| x.attributes[self.right_col_name] <=> y.attributes[self.right_col_name] }

      # Move given node to the left of the largest of all smaller siblings
      self.move_to_left_of(largest_smaller_sibling)
    end

    def move_right
      # Find the smallest of all larger siblings
      larger_siblings = real_siblings.select { |node| node.attributes[self.right_col_name] > self.attributes[self.right_col_name] }
      return if larger_siblings.blank?
      smallest_larger_sibling = larger_siblings.min { |x,y| x.attributes[self.right_col_name] <=> y.attributes[self.right_col_name] }

      # Move given node to the right of the smallest of all larger siblings
      self.move_to_right_of(smallest_larger_sibling)
    end

    def move_up
      return unless self.has_parent?

      # move to right of rightmost parent
      self.move_to_right_of(parent.real_siblings[-1])
    end

    def move_to_root
      return unless self.has_parent?

      # move to right of rightmost root
      self.move_to_right_of(roots[-1])
    end

    def has_children?
      self.attributes[self.left_col_name]+1 != self.attributes[self.right_col_name]
    end

    def has_parent?
      not parent_id.blank?
    end

    def first?
      query =  "SELECT COUNT(*) FROM #{self.class.table_name} WHERE "
      query << "#{self.parent_col_name} = #{self.attributes[self.parent_col_name]} AND " unless self.attributes[self.parent_col_name].blank?
      query << "#{self.left_col_name} < #{self.attributes[self.left_col_name]}"

      count = ActiveRecord::Base.connection.select_value(query).to_i
      count == 0
    end

    def last?
      query =  "SELECT COUNT(*) FROM #{self.class.table_name} WHERE "
      query << "#{self.parent_col_name} = #{self.attributes[self.parent_col_name]} AND " unless self.attributes[self.parent_col_name].blank?
      query << "#{self.left_col_name} > #{self.attributes[self.left_col_name]}"

      count = ActiveRecord::Base.connection.select_value(query).to_i
      count == 0
    end

    # Does the same as siblings, but also works for root nodes
    def real_siblings
      self.has_parent? ? self.siblings : (self.roots - [self])
    end

    

    def sort_children
      return unless self.has_children?

      # Create a sorted array of child tuples
      sorted_children = self.children.sort

      # Create a mapping which maps each id to a left and a right
      mapping = {}
      current_left = children[0].lft
      sorted_children.each do |child|
         # Calculate difference
        lft_old = child.lft
        lft_new = current_left
        difference = lft_new - lft_old

        # Calculate left for next tuple
        width = child.rgt - child.lft
        current_left += width + 1

        # Create mapping
        mapping[child.id] = { :lft => child.lft + difference, :rgt => child.rgt + difference }
        child.all_children.each do |grandchild|
          mapping[grandchild.id] = { :lft => grandchild.lft + difference, :rgt => grandchild.rgt + difference }
        end
      end

      # Update table
      transaction do
        mapping.each do |key, value|
          self.connection.update "UPDATE #{self.class.table_name} SET lft = #{value[:lft]}, rgt = #{value[:rgt]} WHERE id = #{key}"
        end
      end
    end

  end

end
