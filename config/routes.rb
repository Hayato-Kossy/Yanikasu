# config/routes.rb
module Routes
    def self.apply_routes(router, db)
      router.add_route('GET', '/todos', lambda { |req|
        if req.params['id']
          todo_id = req.params['id'].to_i
          todo = db.get('todos', todo_id)
          if todo
            { status: '200 OK', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(todo) }
          else
            { status: '404 Not Found', headers: {'Content-Type' => 'text/plain'}, body: 'Todo not found' }
          end
        else
          todos = db.get_all('todos')
          { status: '200 OK', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(todos) }
        end
      })
  
      router.add_route('POST', '/todos', lambda { |req|
        data = req.json_body
        todo = db.add('todos', data)
        { status: '201 Created', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(todo) }
      })
  
      router.add_route('PUT', '/todos/:id', lambda { |req|
        todo_id = req.params['id'].to_i
        update_data = req.json_body
        updated_todo = db.update('todos', todo_id, update_data)
        if updated_todo
          { status: '200 OK', headers: {'Content-Type' => 'application/json'}, body: JSON.dump(updated_todo) }
        else
          { status: '404 Not Found', headers: {'Content-Type' => 'text/plain'}, body: 'Todo not found' }
        end
      })
  
      router.add_route('DELETE', '/todos/:id', lambda { |req|
        todo_id = req.params['id'].to_i
        if db.delete('todos', todo_id)
          { status: '204 No Content', headers: {}, body: '' }
        else
          { status: '404 Not Found', headers: {'Content-Type' => 'text/plain'}, body: 'Todo not found' }
        end
      })
    end
  end
  