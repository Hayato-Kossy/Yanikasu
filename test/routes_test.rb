require_relative 'test_helper'

class RoutesTest < Minitest::Test
  def test_health_route_is_registered
    router = Router.new
    fake_db = Object.new
    Yanikasu.load_routes(router)
    request = Request.from_raw(<<~HTTP)
      GET /health HTTP/1.1
      Host: localhost

    HTTP

    response = router.find_route_and_execute(request)

    assert_equal '200 OK', response[:status]
    assert_equal '{"status":"ok"}', response[:body]
  end

  def test_db_normalizes_boolean_values
    Dir.mktmpdir do |dir|
      db = DB.new(File.join(dir, 'test.sqlite3'), schema: Yanikasu.load_schema)
      todo = db.add('todos', { 'title' => 'Write tests', 'completed' => true })

      assert_equal true, todo[:completed]
      assert_equal 'Write tests', todo[:title]
    end
  end

  def test_db_rejects_unknown_collection_names
    Dir.mktmpdir do |dir|
      db = DB.new(File.join(dir, 'test.sqlite3'), schema: Yanikasu.load_schema)

      error = assert_raises(ArgumentError) do
        db.get('todos; DROP TABLE todos')
      end

      assert_equal 'Unknown collection: todos; DROP TABLE todos', error.message
    end
  end

  def test_db_rejects_unknown_attribute_names
    Dir.mktmpdir do |dir|
      db = DB.new(File.join(dir, 'test.sqlite3'), schema: Yanikasu.load_schema)

      error = assert_raises(ArgumentError) do
        db.add('todos', { 'title' => 'Write tests', 'danger' => 'oops' })
      end

      assert_equal 'Unknown attributes: danger', error.message
    end
  end

  def test_load_schema_can_define_multiple_collections
    schema = Yanikasu.load_schema

    assert_equal({ 'title' => :string, 'completed' => :boolean }, schema['todos'])
  end
end
