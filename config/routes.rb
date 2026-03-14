# config/routes.rb
require 'json'

module Routes
  def self.apply(router, db)
    router.add_route('GET', '/health', lambda { |_req|
      json_response('200 OK', status: 'ok')
    })

    router.add_route('GET', '/todos', lambda { |_req|
      todos = db.get_all('todos')
      json_response('200 OK', todos)
    })

    router.add_route('GET', '/todos/:id', lambda { |req|
      todo = db.get_item('todos', req.params['id'].to_i)
      return not_found('Todo not found') unless todo

      json_response('200 OK', todo)
    })

    router.add_route('POST', '/todos', lambda { |req|
      todo = db.add('todos', req.json_body)
      json_response('201 Created', todo)
    })

    router.add_route('PUT', '/todos/:id', lambda { |req|
      updated_todo = db.update('todos', req.params['id'].to_i, req.json_body)
      return not_found('Todo not found') unless updated_todo

      json_response('200 OK', updated_todo)
    })

    router.add_route('DELETE', '/todos/:id', lambda { |req|
      if db.delete('todos', req.params['id'].to_i)
        { status: '204 No Content', headers: {}, body: '' }
      else
        not_found('Todo not found')
      end
    })
  end

  def self.json_response(status, body)
    { status: status, headers: { 'Content-Type' => 'application/json' }, body: JSON.dump(body) }
  end

  def self.not_found(message)
    { status: '404 Not Found', headers: { 'Content-Type' => 'text/plain' }, body: message }
  end
end
