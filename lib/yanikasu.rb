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
require_relative '../config/routes'

module Yanikasu
  def self.handle_options_request(socket)
    Response.new(status: '200 OK', headers: CorsMiddleware.apply, body: '').send(socket)
  end

  def self.start_server
    server = TCPServer.new('localhost', 3000)
    db = DB.new
    router = Router.new
    load_routes(router, db)
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

  def self.load_routes(router, db)
    Routes.apply(router, db)
  end
end
