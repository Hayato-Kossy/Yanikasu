# lib/router.rb
require 'json'

class Router
  Route = Struct.new(:method, :path, :action, :regex_pattern, :param_keys, keyword_init: true)
  class RouteContext
    attr_reader :request, :db

    def initialize(request:, db:)
      @request = request
      @db = db
    end

    def params
      request.params
    end

    def json(body = nil, http_status: '200 OK', **payload)
      body = payload unless payload.empty?
      { status: http_status, headers: { 'Content-Type' => 'application/json' }, body: JSON.dump(body) }
    end

    def text(body, status: '200 OK')
      { status: status, headers: { 'Content-Type' => 'text/plain' }, body: body }
    end

    def not_found(message = 'Not Found')
      text(message, status: '404 Not Found')
    end

    def no_content
      { status: '204 No Content', headers: {}, body: '' }
    end
  end

  class DSL
    def initialize(router)
      @router = router
    end

    %w[GET POST PUT PATCH DELETE].each do |http_method|
      define_method(http_method.downcase) do |path, &block|
        raise ArgumentError, "Block is required for #{http_method} #{path}" unless block

        @router.add_route(http_method, path, build_action(block))
      end
    end

    private

    def build_action(block)
      lambda do |request, db|
        context = RouteContext.new(request: request, db: db)
        args = case block.arity
               when 0 then []
               when 1 then [request]
               else [request, db]
               end
        context.instance_exec(*args, &block)
      end
    end
  end

  def initialize()
    @routes = []
  end

  def draw(&block)
    DSL.new(self).instance_eval(&block)
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
