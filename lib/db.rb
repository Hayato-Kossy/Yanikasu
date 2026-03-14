require 'sqlite3'

class DB
  TYPE_MAP = {
    string: 'TEXT',
    text: 'TEXT',
    integer: 'INTEGER',
    boolean: 'INTEGER',
    float: 'REAL'
  }.freeze

  def initialize(db_name = 'db.sqlite3', schema: {})
    @db = SQLite3::Database.new(db_name)
    @db.results_as_hash = true
    @schema = normalize_schema(schema)
    setup_schema
  end

  def setup_schema
    @schema.each do |collection, attributes|
      ensure_table(collection, attributes)
      ensure_columns(collection, attributes)
    end
  end

  def get(collection)
    validate_collection!(collection)
    @db.execute("SELECT * FROM #{collection}").map { |row| hydrate_row(collection, row) }
  end

  def get_all(collection)
    get(collection)
  end

  def add(collection, item)
    validate_collection!(collection)
    validate_attributes!(collection, item)
    normalized_item = normalize_attributes(collection, item)
    columns = normalized_item.keys.join(', ')
    values = normalized_item.map { |key, value| normalize_value(collection, key, value) }
    placeholders = Array.new(values.size, '?').join(', ')
    @db.execute("INSERT INTO #{collection} (#{columns}) VALUES (#{placeholders})", values)
    get_item(collection, @db.last_insert_row_id)
  end

  def update(collection, id, attributes)
    validate_collection!(collection)
    validate_attributes!(collection, attributes)
    normalized_attributes = normalize_attributes(collection, attributes)
    set_clause = normalized_attributes.keys.map { |k| "#{k} = ?" }.join(', ')
    values = normalized_attributes.map { |key, value| normalize_value(collection, key, value) }
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
    hydrate_row(collection, row)
  end

  def execute(sql, binds = [])
    @db.execute(sql, binds)
  end

  def transaction
    @db.transaction
    yield
    @db.commit
  rescue StandardError
    @db.rollback
    raise
  end

  private

  def ensure_table(collection, attributes)
    column_definitions = attributes.map do |name, meta|
      "#{name} #{meta[:sql_type]}"
    end
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS #{collection} (
        id INTEGER PRIMARY KEY,
        #{column_definitions.join(",\n        ")}
      );
    SQL
  end

  def ensure_columns(collection, attributes)
    existing_columns = table_columns(collection)
    attributes.each do |name, meta|
      next if existing_columns.include?(name)

      @db.execute("ALTER TABLE #{collection} ADD COLUMN #{name} #{meta[:sql_type]}")
    end
  end

  def table_columns(collection)
    @db.execute("PRAGMA table_info(#{collection})").map { |column| column['name'] }
  end

  def normalize_schema(schema)
    schema.each_with_object({}) do |(collection, attributes), normalized|
      normalized[collection.to_s] = attributes.each_with_object({}) do |(name, type), cols|
        ruby_type = type.to_sym
        sql_type = TYPE_MAP.fetch(ruby_type) do
          raise ArgumentError, "Unknown schema type: #{type}"
        end
        cols[name.to_s] = { ruby_type: ruby_type, sql_type: sql_type }
      end
    end
  end

  def validate_collection!(collection)
    return if @schema.key?(collection)

    raise ArgumentError, "Unknown collection: #{collection}"
  end

  def validate_attributes!(collection, attributes)
    invalid_keys = normalize_attributes(collection, attributes).keys - @schema.fetch(collection).keys
    return if invalid_keys.empty?

    raise ArgumentError, "Unknown attributes: #{invalid_keys.join(', ')}"
  end

  def normalize_attributes(collection, attributes)
    attributes.each_with_object({}) do |(key, value), normalized|
      normalized[key.to_s] = value
    end
  end

  def normalize_value(collection, key, value)
    type = @schema.fetch(collection).fetch(key).fetch(:ruby_type)
    return 1 if type == :boolean && value == true
    return 0 if type == :boolean && value == false

    value
  end

  def hydrate_row(collection, row)
    return nil unless row

    schema = @schema.fetch(collection)
    result = { id: row['id'] }
    schema.each do |key, meta|
      result[key.to_sym] = cast_value(meta[:ruby_type], row[key])
    end
    result
  end

  def cast_value(type, value)
    return value == 1 if type == :boolean

    value
  end
end
