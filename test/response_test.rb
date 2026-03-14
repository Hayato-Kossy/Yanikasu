require_relative 'test_helper'

class ResponseTest < Minitest::Test
  def test_preserves_explicit_content_type
    socket = StringIO.new
    response = Response.new(
      status: '404 Not Found',
      headers: { 'Content-Type' => 'text/plain' },
      body: 'Not Found'
    )

    response.send(socket)

    payload = socket.string
    assert_includes payload, "HTTP/1.1 404 Not Found\r\n"
    assert_includes payload, "Content-Type: text/plain\r\n"
    assert_includes payload, "Content-Length: 9\r\n"
    assert payload.end_with?("Not Found")
  end

  def test_cors_middleware_merges_default_headers
    headers = CorsMiddleware.apply('Content-Type' => 'application/json')

    assert_equal '*', headers['Access-Control-Allow-Origin']
    assert_equal 'application/json', headers['Content-Type']
  end
end
