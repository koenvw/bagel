module Admin::TagsHelper
  def render_subtree(categories, root_id, output='')
    # Find children of given parent
    children = categories.select { |c| c.parent_id == root_id }
    return output if children.blank?

    # Open list tag
    output << '<ul>'

    children.each do |child|
      # Open list item tag
      output << tag('li', { :id => 'node' + child.id.to_s }, true)

      # Render subtree
      output << link_to(h(child.name), { :action => 'edit', :id => child.id }, :id => 'cat_' + child.id.to_s)
      render_subtree(categories, child.id, output)

      # Close list item tag
      output << '</li>'
    end

    # Close list tag
    output << '</ul>'

    output
  end
end
