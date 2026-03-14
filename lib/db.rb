require 'sqlite3'

class DB
  SCHEMA = {
    'todos' => %w[title completed]
  }.freeze

  def initialize(db_name = 'db.sqlite3')
    @db = SQLite3::Database.new(db_name)
    setup_schema
  end

  def setup_schema
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY,
        title TEXT,
        completed INTEGER
      );
    SQL
  end

  def get(collection)
    validate_collection!(collection)
    @db.execute("SELECT * FROM #{collection}").map do |row|
      { id: row[0], title: row[1], completed: row[2] == 1 }
    end
  end

  def get_all(collection)
    get(collection)
  end

  def add(collection, item)
    validate_collection!(collection)
    validate_attributes!(collection, item)
    columns = item.keys.join(', ')
    values = item.values.map { |v| normalize_value(v) }
    placeholders = Array.new(values.size, '?').join(', ')
    @db.execute("INSERT INTO #{collection} (#{columns}) VALUES (#{placeholders})", values)
    item['id'] = @db.last_insert_row_id
    get_item(collection, item['id'])
  end

  def update(collection, id, attributes)
    validate_collection!(collection)
    validate_attributes!(collection, attributes)
    set_clause = attributes.keys.map { |k| "#{k} = ?" }.join(', ')
    values = attributes.values.map { |v| normalize_value(v) }
    @db.execute("UPDATE #{collection} SET #{set_clause} WHERE id = ?", values + [id])
    get_item(collection, id)
  end

  def delete(collection, id)
    validate_collection!(collection)
    @db.execute("DELETE FROM #{collection} WHERE id = ?", id)
    !@db.changes.zero?
  end

  def get_item(collection, id)
    validate_collection!(collection)
    row = @db.get_first_row("SELECT * FROM #{collection} WHERE id = ?", id)
    return nil unless row
    { id: row[0], title: row[1], completed: row[2] == 1 }
  end

  private

  def normalize_value(value)
    case value
    when true
      1
    when false
      0
    else
      value
    end
  end

  def validate_collection!(collection)
    return if SCHEMA.key?(collection)

    raise ArgumentError, "Unknown collection: #{collection}"
  end

  def validate_attributes!(collection, attributes)
    invalid_keys = attributes.keys - SCHEMA.fetch(collection)
    return if invalid_keys.empty?

    raise ArgumentError, "Unknown attributes: #{invalid_keys.join(', ')}"
  end
end
