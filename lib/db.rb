require 'sqlite3'

class DB
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
    @db.execute("SELECT * FROM #{collection}").map do |row|
      { id: row[0], title: row[1], completed: row[2] == 1 }
    end
  end

  def add(collection, item)
    columns = item.keys.join(', ')
    values = item.values.map { |v| normalize_value(v) }
    placeholders = Array.new(values.size, '?').join(', ')
    @db.execute("INSERT INTO #{collection} (#{columns}) VALUES (#{placeholders})", values)
    item['id'] = @db.last_insert_row_id
    get_item(collection, item['id'])
  end

  def update(collection, id, attributes)
    set_clause = attributes.keys.map { |k| "#{k} = ?" }.join(', ')
    values = attributes.values.map { |v| normalize_value(v) }
    @db.execute("UPDATE #{collection} SET #{set_clause} WHERE id = ?", values + [id])
    get_item(collection, id)
  end

  def delete(collection, id)
    @db.execute("DELETE FROM #{collection} WHERE id = ?", id)
    !@db.changes.zero?
  end

  def get_item(collection, id)
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
end
