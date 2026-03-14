Yanikasu.draw_routes do
  get '/health' do
    json(status: 'ok')
  end

  get '/todos' do
    json(db.get_all('todos'))
  end

  get '/todos/:id' do |req|
    todo = db.get_item('todos', req.params['id'].to_i)
    return not_found('Todo not found') unless todo

    json(todo)
  end

  post '/todos' do |req|
    todo = db.add('todos', req.json_body)
    json(todo, http_status: '201 Created')
  end

  put '/todos/:id' do |req|
    updated_todo = db.update('todos', req.params['id'].to_i, req.json_body)
    return not_found('Todo not found') unless updated_todo

    json(updated_todo)
  end

  delete '/todos/:id' do |req|
    if db.delete('todos', req.params['id'].to_i)
      no_content
    else
      not_found('Todo not found')
    end
  end
end
