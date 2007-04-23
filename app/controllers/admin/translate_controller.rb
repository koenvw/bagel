class Admin::TranslateController < ApplicationController

  def index
  # Locale.set("fr-FR")
    @view_translations = ViewTranslation.find(:all, :conditions => [ 'text IS NULL AND language_id = ?', Locale.language.id ], :order => 'tr_key')
  end

  def translation_text
    @translation = ViewTranslation.find(params[:id])
    render :text => @translation.text || ""
  end

  def set_translation_text
    @translation = ViewTranslation.find(params[:id])
    previous = @translation.text
    @translation.text = params[:value]
    @translation.text = previous unless @translation.save
    render :partial => "translation_text", :object => @translation.text
  end

end
