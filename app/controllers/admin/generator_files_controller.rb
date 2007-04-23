class Admin::GeneratorFilesController < ApplicationController
  requires_authorization :actions => [:index, :list, :edit, :destroy],
                         :permission => [:admin_generator_files_management,:_admin_management]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :list }

  def list
    @generator_files_pages, @generator_files = paginate :generator_files, :per_page => 100, :order => "name asc"
  end

  def edit
    @generator_file = GeneratorFile.find_by_id(params[:id]) || GeneratorFile.new
    if request.post?
      @generator_file.attributes = params[:generator_file]
      if @generator_file.save
        html = render_to_string :inline => @generator_file.generator.template
        File.open(@generator_file.file_path, "w") do |file|
          file << html
        end
        flash[:notice] ='GeneratorFile was successfully updated.'
        redirect_to :action => 'list'
      end
    end
  end


  def destroy
    GeneratorFile.find(params[:id]).destroy
    redirect_to :controller => 'generator_files', :action => 'list'
  end

  # FIXME: duplicated from SiteController
  def render_generator(generator)
    logger.debug "Rendered generator: #{generator}"
    gen = Generator.find_by_name(generator)
    if gen.nil?
      "can not find generator '#{generator}'"
    else
      render_to_string :inline => gen.template
    end
  end

end
