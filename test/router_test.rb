require_relative 'test_helper'

class RouterTest < Minitest::Test
  def test_matches_named_route_parameters
    router = Router.new
    router.add_route('GET', '/todos/:id', lambda { |req|
      { status: '200 OK', headers: { 'Content-Type' => 'application/json' }, body: req.params['id'] }
    })
    request = Request.from_raw(<<~HTTP)
      GET /todos/42 HTTP/1.1
      Host: localhost

    HTTP

    response = router.find_route_and_execute(request)

    assert_equal '42', response[:body]
    assert_equal '42', request.params['id']
  end
end
