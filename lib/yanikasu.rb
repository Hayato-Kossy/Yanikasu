# lib/yanikasu.rb
# ルーティングはcliからconfig/routes.rbに書き込み、読み込むように変更したい
# ハンドラーも分離したい
require 'socket'
require 'json'
require_relative 'router'
require_relative 'request'
require_relative 'response'
require_relative 'db'
require_relative '../middleware/cors'

module Yanikasu
  class SchemaDSL
    def initialize
      @schema = {}
    end

    def collection(name, &block)
      builder = CollectionDSL.new
      builder.instance_eval(&block)
      @schema[name.to_s] = builder.to_h
    end

    def to_h
      @schema
    end
  end

  class CollectionDSL
    def initialize
      @attributes = {}
    end

    %i[string text integer boolean float].each do |type|
      define_method(type) do |name|
        @attributes[name.to_s] = type
      end
    end

    def to_h
      @attributes
    end
  end

  def self.handle_options_request(socket)
    Response.new(status: '200 OK', headers: CorsMiddleware.apply, body: '').send(socket)
  end

  def self.start_server
    server = TCPServer.new('localhost', 3000)
    db = DB.new('db.sqlite3', schema: load_schema)
    router = Router.new
    load_routes(router)
    puts "Server is running on http://localhost:3000/"
    loop do
      socket = server.accept
      begin
        request = Request.new(socket)
        process_request(socket, request, router, db)
      rescue ArgumentError => e
        Response.new(
          status: '400 Bad Request',
          headers: CorsMiddleware.apply('Content-Type' => 'application/json'),
          body: { error: e.message }
        ).send(socket)
      ensure
        socket.close unless socket.closed?
      end
    end
  end

  def self.process_request(socket, request, router, db)
    if request.method == 'OPTIONS'
      handle_options_request(socket)
      return
    end

    response = router.find_route_and_execute(request, db)
    resp = Response.new(
      status: response[:status],
      headers: CorsMiddleware.apply(response[:headers] || {}),
      body: response[:body] || ''
    )
    resp.send(socket)
    puts response[:body]
  rescue JSON::ParserError
    Response.new(
      status: '400 Bad Request',
      headers: CorsMiddleware.apply('Content-Type' => 'application/json'),
      body: { error: 'Invalid JSON body' }
    ).send(socket)
  rescue StandardError => e
    Response.new(
      status: '500 Internal Server Error',
      headers: CorsMiddleware.apply('Content-Type' => 'application/json'),
      body: { error: 'Internal Server Error', detail: e.message }
    ).send(socket)
  end

  def self.draw_routes(&block)
    @routes_block = block
  end

  def self.define_schema(&block)
    builder = SchemaDSL.new
    builder.instance_eval(&block)
    @schema_definition = builder.to_h
  end

  def self.load_routes(router)
    @routes_block = nil
    load File.expand_path('../config/routes.rb', __dir__)
    raise ArgumentError, 'No routes defined in config/routes.rb' unless @routes_block

    router.draw(&@routes_block)
  end

  def self.load_schema
    @schema_definition = nil
    schema_file = File.expand_path('../config/schema.rb', __dir__)
    load schema_file if File.exist?(schema_file)
    @schema_definition || {}
  end
end
