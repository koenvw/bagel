namespace :bagel do

  desc 'Converts Image objects to Pictures'
  task :convert_images => :environment do
    # Create content types for PictureFileSystem
    picture_ctype = ContentType.find_by_name('Picture (Filesystem)')
    if picture_ctype.nil?
      picture_ctype = ContentType.create :core_content_type => 'MediaItem',
                                         :name              => 'Picture (Filesystem)',
                                         :description       => 'A picture stored on the server.',
                                         :extra_info        => 'PictureFileSystem'
    end

    # Find Image content type (assuming there is only one)
    image_ctype = ContentType.find_by_name('Image')

    # Find image relations
    image_relations_from = image_ctype.relations
    image_relations_to   = Relation.find(:all, :conditions => [ 'content_type_id = ?', image_ctype.id ])

    # Create relations
    picture_relations_from_hash = {}
    picture_relations_to_hash   = {}
    image_relations_from.each do |image_relation|
      # Workaround for content_type_id being overwritten in that JOIN...
      real_content_type_id = Relation.find(image_relation.id).content_type_id
      # Image content type is in image_relation.content_types
      picture_relation = Relation.create(:name => image_relation.name + ' (updated)', :content_type_id => real_content_type_id)
      image_relation.content_types.each do |ct|
        picture_relation.content_types << (ct == image_ctype ? picture_ctype : ct)
      end
      picture_relations_from_hash[image_relation] = picture_relation
    end
    image_relations_to.each do |image_relation|
      # Image content type is image_relation.content_type
      picture_relation = Relation.create(:name => image_relation.name + ' (updated)', :content_type_id => picture_ctype.id)
      image_relation.content_types.each { |ct| picture_relation.content_types << ct }
      picture_relations_to_hash[image_relation] = picture_relation
    end

    # For each image...
    Image.find(:all).each do |image|
      # Get image file path
      public_path = image.image_options[:base_url] + '/' + image.image_relative_path
      full_path = Pathname.new(RAILS_ROOT + '/public/' + public_path).realpath.to_s

      # Read file
      file = File.open(full_path)
      file.extend FileCompat

      # Create a picture
      picture = PictureFileSystem.new
      picture[:type]        = 'PictureFileSystem'
      picture.type_id       = picture_ctype.id
      picture.attributes    = {
        :title          => image.title,
        :description    => image.description,
        :uploaded_data  => file
      }
      picture.content_type = MIME::Types.type_for(full_path).to_s
      picture.save

      # We're done with file
      file.close

      # Update sobject
      attrs = [ :updated_by ]
      attrs.each { |attr| picture.sobject[attr] = image.sobject[attr] }
      picture.sobject.save

      # Update sitems
      picture.sitems.each do |sitem|
        # Find sitem for image
        matching_sitem = (image.sitems.select { |s| s.website_id == sitem.website_id } || []).first
        next if matching_sitem.nil?

        # Update this sitem
        attrs = [ :is_published, :website_id, :publish_date, :publish_from, :publish_till ]
        attrs.each { |attr| sitem[attr] = matching_sitem[attr] }
        sitem.save
      end

      # Update tags
      image.tags.each { |t| picture.tags << t }

      # Update relationships
      image.sobject.relations_as_from.each do |relationship|
        # Find new relation for this relationship (image relation -> picture relation)
        relation = relationship.relation
        picture_relation = picture_relations_from_hash[relation]

        # Copy image relations to picture relations
        if picture_relation.nil?
          picture.sobject.relations_as_from << relationship
        else
          new_relationship = relationship.clone
          new_relationship.from     = picture.sobject
          new_relationship.relation = picture_relation
          new_relationship.save
          picture.sobject.relations_as_from << new_relationship
        end
      end
      image.sobject.relations_as_to.each do |relationship|
        # Find new relation for this relationship (image relation -> picture relation)
        relation = relationship.relation
        picture_relation = picture_relations_to_hash[relation]

        # Copy image relations to picture relations
        if picture_relation.nil?
          picture.sobject.relations_as_to << relationship
        else
          new_relationship = relationship.clone
          new_relationship.to       = picture.sobject
          new_relationship.relation = picture_relation
          new_relationship.save
          picture.sobject.relations_as_to << new_relationship
        end
      end

    end

  end

end
