require_relative 'test_helper'

class RequestTest < Minitest::Test
  def test_parses_query_parameters_with_url_decoding
    request = Request.from_raw(<<~HTTP)
      GET /todos?title=hello%20world&completed=true HTTP/1.1
      Host: localhost

    HTTP

    assert_equal 'GET', request.method
    assert_equal '/todos', request.path
    assert_equal({ 'title' => 'hello world', 'completed' => 'true' }, request.params)
  end

  def test_returns_empty_hash_for_missing_body
    request = Request.from_raw(<<~HTTP)
      POST /todos HTTP/1.1
      Host: localhost
      Content-Length: 0

    HTTP

    assert_equal({}, request.json_body)
  end
end
