module ActsAsAssistant

  def self.append_features(base)
    super

    class << base
      attr_accessor :assistant_id
      attr_accessor :assistant_title
      attr_accessor :assistant_steps
    end

    base.extend(ClassMethods)
  end

  module ClassMethods

    def acts_as_assistant(params={})
      self.assistant_id =    params[:identifier]
      self.assistant_title = params[:title]
      self.assistant_steps = params[:steps]

      before_filter(:only => (1..params[:steps].size).map { |x| "step_#{x}".to_sym }) do |controller|
        controller.class.assistant_id     = params[:identifier]
        controller.class.assistant_title  = params[:title]
        controller.class.assistant_steps  = params[:steps]

        controller.instance_eval do
          @assistant_title  = params[:title]
          @assistant_steps  = params[:steps]
        end
      end

      class_eval { include InstanceMethods }
    end

  end

  module InstanceMethods

    ##### ACTIONS

    def index
      redirect_to(params.update({:action => 'step_1'}))
    end

    def restart
      reset_data
      redirect_to :action => 'index'
    end

    ##### SESSION HELPER FUNCTIONS

    def load_data(key)
      fix_data
      session[:assistants][self.class.assistant_id][key]
    end

    def fix_data
      session[:assistants] ||= {}
      session[:assistants][self.class.assistant_id] ||= {}
    end

    def store_data(key, value)
      fix_data

      # Extract data
      if value.respond_to?(:read)
        data = session[:assistants][self.class.assistant_id][key] = value.read
      elsif value.respond_to?(:string)
        data = session[:assistants][self.class.assistant_id][key] = value.string
      else
        data = value
      end

      if value.respond_to?(:original_filename) and value.respond_to?(:content_type) and value.respond_to?(:size)
        # Store value as well as extra data
        session[:assistants][self.class.assistant_id][key] = {
          :original_filename  => value.original_filename,
          :content_type       => value.content_type,
          :size               => value.size,
          :data               => data
        }
      else
        # Store data
        session[:assistants][self.class.assistant_id][key] = data
      end
    end

    def reset_data
      fix_data
      session[:assistants][self.class.assistant_id] = {}
    end

  end

end
