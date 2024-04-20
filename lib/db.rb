require 'json'

class DB
  def initialize(filename = 'db.json')
    @filename = filename
    @data = load_data
  end

  def load_data
    if File.exist?(@filename)
      JSON.parse(File.read(@filename))
    else
      {}
    end
  end

  def save_data
    File.open(@filename, 'w') do |file|
      file.write(JSON.pretty_generate(@data))
    end
  end

  def get(collection)
    @data[collection] || []
  end

  def add(collection, item)
    @data[collection] ||= []
    new_id = (@data[collection].map { |i| i['id'] }.max || 0) + 1
    item['id'] = new_id
    @data[collection] << item
    save_data
    item
  end

  def update(collection, id, attributes)
    item = @data[collection].find { |i| i['id'] == id }
    return nil unless item
    item.update(attributes)
    save_data
    item
  end

  def delete(collection, id)
    original_length = @data[collection].length
    @data[collection].reject! { |i| i['id'] == id }
    save_data
    original_length != @data[collection].length
  end
end
