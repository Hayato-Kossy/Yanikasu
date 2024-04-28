# lib/router.rb
# DB持ってるの良くない
class Router
  def initialize()
    @routes = {}
  end

  def add_route(method, path, action)
    @routes["#{method} #{path}"] = action
  end

  def find_route_and_execute(request,db)
    request_method_path = "#{request.method} #{request.path}"
    @routes.each do |pattern, action|
      regex_pattern = Regexp.new("^" + pattern.gsub(/:[^\s\/]+/, '([^\/]+)') + "$")
      if match = regex_pattern.match(request_method_path)
        request.params.merge!(extract_route_params(pattern, match.captures))
        return action.call(request,db)  
      end
    end
    { status: '404 Not Found', headers: {'Content-Type': 'text/plain'}, body: 'Not Found' }
  end

  private

  def extract_route_params(pattern, captures)
    keys = pattern.scan(/:([^\s\/]+)/).flatten
    Hash[keys.zip(captures)]
  end
end
