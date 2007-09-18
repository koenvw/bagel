class Admin::TranslationsController < ApplicationController

  requires_authorization :actions    => [ :index, :translate ],
                         :permission => [ :content_translation_management ]

  helper 'admin/forms'

  def index
    # Find all sobjects that are inversely translation-related to a sobject that is past a translatable workflow step.

    # Warning:
    # These are a few queries which should hopefully be mergeable into one bigger and faster query.

    # 1. Find all translatable workflow steps.
    translatable_workflow_steps         = WorkflowStep.find_all_by_is_translatable(true)

    # 2. Find all workflow actions corresponding to said steps.
    translatable_workflow_actions       = translatable_workflow_steps.map(&:workflow_actions).flatten

    # 3. Find all sobjects with said actions (sobjects that are past a translatable step)
    translatable_sobjects               = translatable_workflow_actions.map(&:sobject).compact

    # 4. Find all relations from said sobjects
    translatable_sobject_relationships  = translatable_sobjects.map(&:relations_as_from).flatten

    # 5. Find all translation relations
    translation_relations_pub           = translatable_sobject_relationships.select { |r| r.relation.is_translation_relation? }

    # 6. Find all translation relations that are not published
    @translation_relations              = translation_relations_pub.reject { |r| r.to.published_async? }
  end

  def translate
    # Find relation
    begin
      @relationship = Relationship.find(params[:id])
      raise 'Not a translation relation' unless @relationship.relation.is_translation_relation?
    rescue
      flash[:error] = "You cannot edit this translation."
      redirect_to :action => 'index'
      return
    end

    @type = @relationship.to.content.ctype.core_content_type.downcase.to_sym # :form or :news

    if request.post?
      @relationship.to.content.save_workflow(params[:workflow_steps])

      if @type == :form
        @relationship.to.content.name = params[:form][:name]
        @relationship.to.content.data = params[:form]
        @relationship.to.content.save
       elsif @type == :news
        @relationship.to.content.title = params[:news][:title]
        @relationship.to.content.intro = params[:news][:intro]
        @relationship.to.content.body  = params[:news][:body]
        @relationship.to.content.save
      end

      flash[:notice] = "Translation updated!"
      redirect_to :action => 'index'
    end
  end

end
