# lib/router.rb
# DB持ってるの良くない
class Router
  Route = Struct.new(:method, :path, :action, :regex_pattern, :param_keys, keyword_init: true)

  def initialize()
    @routes = []
  end

  def add_route(method, path, action)
    compiled = compile_route(method, path)
    @routes << Route.new(
      method: method,
      path: path,
      action: action,
      regex_pattern: compiled[:regex_pattern],
      param_keys: compiled[:param_keys]
    )
  end

  def find_route_and_execute(request, db = nil)
    request_method_path = "#{request.method} #{request.path}"
    @routes.each do |route|
      if match = route.regex_pattern.match(request_method_path)
        request.params.merge!(extract_route_params(route.param_keys, match.captures))
        return invoke_action(route.action, request, db)
      end
    end

    { status: '404 Not Found', headers: { 'Content-Type' => 'text/plain' }, body: 'Not Found' }
  end

  private

  def compile_route(method, path)
    pattern = "#{method} #{path}"
    {
      regex_pattern: Regexp.new("^" + pattern.gsub(/:[^\s\/]+/, '([^\/]+)') + "$"),
      param_keys: path.scan(/:([^\s\/]+)/).flatten
    }
  end

  def extract_route_params(keys, captures)
    Hash[keys.zip(captures)]
  end

  def invoke_action(action, request, db)
    return action.call(request) if action.arity == 1

    action.call(request, db)
  end
end
