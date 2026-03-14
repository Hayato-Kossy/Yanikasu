require_relative 'test_helper'

class CLITest < Minitest::Test
  FakeTime = Struct.new(:value) do
    def now
      value
    end
  end

  def test_init_generates_config_files
    Dir.mktmpdir do |dir|
      stdout = StringIO.new
      stderr = StringIO.new

      status = CLI.new(stdout: stdout, stderr: stderr, cwd: dir).run(['init'])

      assert_equal 0, status
      assert File.exist?(File.join(dir, 'config/routes.rb'))
      assert File.exist?(File.join(dir, 'config/schema.rb'))
      assert Dir.exist?(File.join(dir, 'migrations'))
    end
  end

  def test_generate_migration_creates_timestamped_file
    Dir.mktmpdir do |dir|
      stdout = StringIO.new
      stderr = StringIO.new
      time_source = FakeTime.new(Time.new(2026, 3, 14, 12, 34, 56, '+09:00'))

      status = CLI.new(stdout: stdout, stderr: stderr, cwd: dir, time_source: time_source)
                  .run(['generate', 'migration', 'create_posts'])

      assert_equal 0, status
      assert File.exist?(File.join(dir, 'migrations/20260314123456_create_posts.rb'))
    end
  end

  def test_generate_migration_rejects_invalid_name
    Dir.mktmpdir do |dir|
      stdout = StringIO.new
      stderr = StringIO.new

      status = CLI.new(stdout: stdout, stderr: stderr, cwd: dir).run(['generate', 'migration', 'CreatePosts'])

      assert_equal 1, status
      assert_includes stderr.string, 'migration 名は snake_case で指定してください'
    end
  end
end
