class Admin::NewsController < ApplicationController

  requires_authorization :actions => [:index, :edit, :destroy],
                         :permission => [:content_news_management,:_content_management]
  uses_tiny_mce tinymce_options

  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :edit }

  helper "admin/forms"

  def index
    edit
    render :action => 'edit'
  end

  def edit
    @news = News.find_by_id(params[:id]) || News.new
    @newcomment = Comment.new
    @languages = Setting.languages
    @news.type_id ||= params[:type_id]
    @news.create_default_sitems # in case new websites were created after this item was created

    @news_has_sub_title =  (Setting.get("ContentTypeSettings") && Setting.get("ContentTypeSettings")[:news_has_sub_title]) || false

    if request.post?
      old_attributes = @news.attributes
      is_new_item = @news.id.blank?

      @news.attributes = params[:news]
      @news.prepare_sitems(params[:sitems])

      begin
        News.transaction do
          @news.save(false)

          # Save other stuff
          @news.save_tags(params[:tags])
          @news.save_comment(params[:newcomment])
          @news.save_relations(params[:relations])
          @news.set_updated_by(params)
          @news.save_workflow(params[:workflow_steps])

          @news.reload # make sure our tags/relations are up to date

          # Save language
          @news.save_language(params[:sobject] && params[:sobject][:language])
          @news.sobject.publish_synced = params[:publish_synced]

          if @news.save! # will throw ActiveRecord::RecordInvalid and rollback the transaction
            # Create translated items if necessary
            # FIXME this is duplicated in forms controller... perhaps move this elsewhere?
            language_codes = (params[:requested_translations] || {}).keys.map(&:to_s)
            language_codes.each do |language_code|
              # Skip language when there is already an existing object
              next if @news.sobject.language == language_code
              next unless @news.sobject.relations_as_from.select { |r| r.to.language == language_code }.empty?

              News.transaction do
                # Clone object
                new_news = News.new
                new_news.title              = @news.title + " [Untranslated #{Setting.language_name_for_code(language_code)}]"
                new_news.body               = @news.body
                new_news.prepare_sobject

                # Clone sobject
                new_news.sobject.language         = language_code.to_s
                new_news.sobject.content_type     = @news.sobject.content_type
                new_news.sobject.content_type_id  = @news.sobject.content_type_id
                new_news.sobject.created_by       = @news.sobject.created_by
                new_news.sobject.updated_by       = @news.sobject.updated_by

                new_news.sobject.save
                new_news.save

                # Clone tags
                @news.sobject.tags.each { |tag| new_news.sobject.tags << tag }

                # Clone relationships
                @news.sobject.relations_as_from.each do |relationship|
                  new_relationship = relationship.clone
                  new_relationship.from_sobject_id = new_news.sobject.id
                  new_relationship.save
                end
                @news.sobject.relations_as_to.each do |relationship|
                  new_relationship = relationship.clone
                  new_relationship.to_sobject_id = new_news.sobject.id
                  new_relationship.save
                end

                # Create two translation relationships
                # FIXME Try to change relations in such a way that many-to-many relations are possible
                relation = Relation.find_by_name("Translation - #{@news.sobject.ctype.name}")
                raise "Unable to find relation named 'Translation - #{@news.sobject.ctype.name}'" if relation.nil?
                @news.add_relation_unless(new_news.sobject.id, relation.id)

              end
            end

            # Share on del.icio.us
            share_on_delicious(@news, params[:sharing_delicious_site]) if params[:sharing_delicious]

            # Log
            diff = old_attributes.inspect_with_newlines.html_diff_with(@news.attributes.inspect_with_newlines)
            bagel_log :message    => "News item #{is_new_item ? 'created' : 'updated'}",
                      :kind       => 'data',
                      :severity   => :low,
                      :extra_info => { :diff => diff, :news => @news }

            # Done
            flash[:notice] = 'Newsitem was successfully updated.'
            redirect_to params[:referer] || {:controller => "content", :action => "list"} 
          end

        end # end transaction

      rescue ActiveRecord::RecordInvalid
        # do nothing
      end
    end
  end

  def destroy
    News.find(params[:id]).destroy
    flash[:notice] = 'Item was successfully destroyed.'
    redirect_to :back
  end

end
