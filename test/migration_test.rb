require_relative 'test_helper'

class MigrationTest < Minitest::Test
  def test_run_pending_migrations_executes_each_file_once
    Dir.mktmpdir do |dir|
      db_path = File.join(dir, 'test.sqlite3')
      migrations_path = File.join(dir, 'migrations')
      Dir.mkdir(migrations_path)

      File.write(
        File.join(migrations_path, '20260314010101_create_posts.rb'),
        <<~RUBY
          Yanikasu.migration do
            execute <<~SQL
              CREATE TABLE posts (
                id INTEGER PRIMARY KEY,
                title TEXT
              );
            SQL
          end
        RUBY
      )

      File.write(
        File.join(migrations_path, '20260314010202_add_published_to_posts.rb'),
        <<~RUBY
          Yanikasu.migration do
            execute "ALTER TABLE posts ADD COLUMN published INTEGER"
          end
        RUBY
      )

      db = DB.new(db_path, schema: {})
      Yanikasu.run_pending_migrations(db, path: migrations_path)
      Yanikasu.run_pending_migrations(db, path: migrations_path)

      versions = db.execute('SELECT version FROM schema_migrations ORDER BY version').map do |row|
        row['version']
      end
      columns = db.execute('PRAGMA table_info(posts)').map { |row| row['name'] }

      assert_equal %w[20260314010101_create_posts 20260314010202_add_published_to_posts], versions
      assert_equal %w[id title published], columns
    end
  end

  def test_load_migration_uses_explicit_version_when_defined
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'custom.rb')
      File.write(
        path,
        <<~RUBY
          Yanikasu.migration 'custom_version' do
            execute 'SELECT 1'
          end
        RUBY
      )

      definition = Yanikasu.load_migration(path)

      assert_equal 'custom_version', definition[:version]
    end
  end
end
