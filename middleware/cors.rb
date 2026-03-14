class CorsMiddleware
  DEFAULT_HEADERS = {
    'Access-Control-Allow-Origin' => '*',
    'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
  }.freeze

  def self.apply(headers = {})
    DEFAULT_HEADERS.merge(headers)
  end
end
