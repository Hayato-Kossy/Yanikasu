require_relative 'test_helper'

class YanikasuTest < Minitest::Test
  def test_server_config_uses_defaults
    config = Yanikasu.server_config(env: {})

    assert_equal 'localhost', config[:host]
    assert_equal 3000, config[:port]
    assert_equal 'db.sqlite3', config[:db_name]
  end

  def test_server_config_uses_environment_variables
    config = Yanikasu.server_config(
      env: {
        'YANIKASU_HOST' => '0.0.0.0',
        'YANIKASU_PORT' => '4567',
        'YANIKASU_DB_PATH' => 'tmp/app.sqlite3'
      }
    )

    assert_equal '0.0.0.0', config[:host]
    assert_equal 4567, config[:port]
    assert_equal 'tmp/app.sqlite3', config[:db_name]
  end

  def test_server_config_prefers_explicit_arguments
    config = Yanikasu.server_config(
      env: { 'YANIKASU_PORT' => '4567' },
      host: '127.0.0.1',
      port: 9292,
      db_name: 'tmp/test.sqlite3'
    )

    assert_equal '127.0.0.1', config[:host]
    assert_equal 9292, config[:port]
    assert_equal 'tmp/test.sqlite3', config[:db_name]
  end
end
