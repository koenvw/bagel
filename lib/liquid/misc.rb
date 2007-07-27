require 'erb' # For ERB:Util.h

# Class that manages secondary hashes and automatically calls where appropriate
class AutoCallingHash
  def initialize(primary, secondary=nil)
    @primary   = primary
    @secondary = secondary
  end

  def [](key)
    value = @primary[key]
    value = @secondary[key] if value.nil? and !@secondary.nil?
    value.respond_to?(:call) ? value.call : value
  end

  def method_missing(method, *args, &block)
    @primary.call(method, *args, &block)
  end
end

def liquid_template(gen, assigns, template=nil)
  begin
    res = Liquid::Template.parse(template || gen.template).render!(assigns)
  rescue => e
    controller = assigns['site_controller'].site_controller
    handle_liquid_exception(e, controller, controller.request)
  end
  res
end

def on_liquid_stack(name)
  $_bagel_liquid_template_stack ||= []
  
  $_bagel_liquid_template_stack.push(name)
  begin
    yield
  ensure
    $_bagel_liquid_template_stack.pop
  end
end

def handle_liquid_exception(exception, controller, request)
  # Gather data about exception
  session = controller.request.session.instance_variables.inject({}) do |memo, var|
    memo.merge({ var => controller.request.session.instance_variable_get(var) })
  end
  data = {
    :generator_backtrace => $_bagel_liquid_template_stack,
    :function_backtrace  => exception.backtrace,
    :is_liquid_exception => true,
    :environment         => ENV.to_hash,
    :controller          => {
      :params              => controller.params,
      :request             => controller.request.params,
      :session             => session
    }
  }

  # Log exception
  controller.bagel_log :exception => exception, :severity => :high, :kind => 'exception', :extra_info => data, :hostname => request.host_with_port

  # Display error
  controller.render_500(true)
end
