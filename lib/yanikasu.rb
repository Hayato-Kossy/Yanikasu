# lib/yanikasu.rb
# ルーティングはcliからconfig/routes.rbに書き込み、読み込むように変更したい
# ハンドラーも分離したい
require 'socket'
require_relative 'router'
require_relative 'request'
require_relative 'response'
require_relative 'db'

module Yanikasu
  def self.handle_options_request(socket)
    cors_headers = "Access-Control-Allow-Origin: *\r\n" +
                   "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\n" +
                   "Access-Control-Allow-Headers: Content-Type, Authorization\r\n" +
                   "Content-Length: 0\r\n\r\n"
  
    socket.print "HTTP/1.1 200 OK\r\n" + cors_headers
    socket.close  
  end
  def self.start_server
    server = TCPServer.new('localhost', 3000)
    db = DB.new
    router = Router.new(db)
    load_routes(router)
    puts "Server is running on http://localhost:3000/"
    loop do
  socket = server.accept     
  request = Request.new(socket) 
  if request.method == 'OPTIONS'
    handle_options_request(socket)
    next
  else
    response = router.route(request)
    resp = Response.new(
  status: response[:status],
  headers: response[:headers],
  body: response[:body]
    )
    resp.send(socket)
    puts response[:body]
  end

  socket.close
    end
  end

  def self.load_routes(router)
    router.add_route('GET', '/todos', method(:get_all_todos))
    router.add_route('GET', '/todos/:id', method(:get_todo))
    router.add_route('POST', '/todos', method(:create_todo))
    router.add_route('PUT', '/todos/:id', method(:update_todo))
    router.add_route('DELETE', '/todos/:id', method(:delete_todo))
  end

  def self.get_all_todos(req, db)
    todos = db.get('todos')
    { status: '200 OK', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(todos) }
  end

  def self.get_todo(req, db)
    todo_id = req.params['id'].to_i
    todo = db.get('todos').find { |item| item['id'] == todo_id }
    if todo
      { status: '200 OK', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(todo) }
    else
      { status: '404 Not Found', headers: {'Content-Type' => 'text/plain'}, body: 'Todo not found' }
    end
  end

  def self.create_todo(req, db)
    data = req.json_body
    todo = db.add('todos', data)
    { status: '201 Created', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(todo) }
  end

  def self.update_todo(req, db)
    todo_id = req.params['id'].to_i
    update_data = req.json_body
    updated_todo = db.update('todos', todo_id, update_data)
    if updated_todo
      { status: '200 OK', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(updated_todo) }
    else
      { status: '404 Not Found', headers: {'Content-Type' => 'text/plain'}, body: 'Todo not found' }
    end
  end

  def self.delete_todo(req, db)
    todo_id = req.params['id'].to_i
    if db.delete('todos', todo_id)
      { status: '204 No Content', headers: {}, body: '' }
    else
      { status: '404 Not Found', headers: {'Content-Type' => 'text/plain'}, body: 'Todo not found' }
    end
  end

end
