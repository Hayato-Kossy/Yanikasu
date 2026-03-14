class CLI
  ROUTES_TEMPLATE = <<~RUBY
    Yanikasu.draw_routes do
      get '/health' do
        json(status: 'ok')
      end
    end
  RUBY

  SCHEMA_TEMPLATE = <<~RUBY
    Yanikasu.define_schema do
    end
  RUBY

  MIGRATION_TEMPLATE = <<~RUBY
    Yanikasu.migration do
    end
  RUBY

  def initialize(stdout: $stdout, stderr: $stderr, cwd: Dir.pwd, time_source: Time)
    @stdout = stdout
    @stderr = stderr
    @cwd = cwd
    @time_source = time_source
  end

  def run(argv)
    command = argv.shift

    case command
    when 'init'
      init_project
    when 'generate'
      run_generate(argv)
    else
      print_usage
      1
    end
  end

  private

  def init_project
    ensure_directory('config')
    ensure_directory('migrations')
    write_if_missing('config/routes.rb', ROUTES_TEMPLATE)
    write_if_missing('config/schema.rb', SCHEMA_TEMPLATE)
    @stdout.puts '初期ファイルを生成しました'
    0
  end

  def run_generate(argv)
    subcommand = argv.shift
    case subcommand
    when 'migration'
      generate_migration(argv.shift)
    when 'resource'
      generate_resource(argv.shift, argv)
    else
      print_usage
      1
    end
  end

  def generate_migration(name)
    unless valid_generator_name?(name)
      @stderr.puts 'migration 名は snake_case で指定してください'
      return 1
    end

    ensure_directory('migrations')
    timestamp = @time_source.now.strftime('%Y%m%d%H%M%S')
    path = File.join('migrations', "#{timestamp}_#{name}.rb")
    write_if_missing(path, MIGRATION_TEMPLATE)
    @stdout.puts "migration を生成しました: #{path}"
    0
  end

  def generate_resource(name, field_args)
    unless valid_generator_name?(name)
      @stderr.puts 'resource 名は複数形の snake_case で指定してください'
      return 1
    end

    fields = parse_fields(field_args)
    return 1 unless fields

    ensure_directory('config')
    ensure_directory('migrations')
    write_if_missing('config/routes.rb', ROUTES_TEMPLATE)
    write_if_missing('config/schema.rb', SCHEMA_TEMPLATE)

    append_schema_resource(name, fields)
    append_routes_resource(name)
    generate_resource_migration(name, fields)
    @stdout.puts "resource を生成しました: #{name}"
    0
  end

  def parse_fields(field_args)
    field_args.map do |field|
      name, type = field.split(':', 2)
      unless valid_generator_name?(name) && valid_field_type?(type)
        @stderr.puts 'field は name:type 形式で、type は string text integer boolean float のいずれかを指定してください'
        return nil
      end

      [name, type]
    end
  end

  def append_schema_resource(name, fields)
    path = File.join(@cwd, 'config/schema.rb')
    content = File.read(path)
    block = build_schema_block(name, fields)
    updated = inject_before_final_end(content, block)
    File.write(path, updated)
  end

  def append_routes_resource(name)
    path = File.join(@cwd, 'config/routes.rb')
    content = File.read(path)
    updated = inject_before_final_end(content, build_routes_block(name))
    File.write(path, updated)
  end

  def generate_resource_migration(name, fields)
    timestamp = @time_source.now.strftime('%Y%m%d%H%M%S')
    path = File.join('migrations', "#{timestamp}_create_#{name}.rb")
    body = build_migration_template(name, fields)
    write_if_missing(path, body)
  end

  def build_schema_block(name, fields)
    lines = ["  collection :#{name} do"]
    fields.each do |field_name, type|
      lines << "    #{type} :#{field_name}"
    end
    lines << '  end'
    "\n#{lines.join("\n")}\n"
  end

  def build_routes_block(name)
    singular = singularize(name)
    <<~RUBY

      get '/#{name}' do
        json(db.get_all('#{name}'))
      end

      get '/#{name}/:id' do |req|
        #{singular} = db.get_item('#{name}', req.params['id'].to_i)
        next not_found('#{singular.capitalize} not found') unless #{singular}

        json(#{singular})
      end

      post '/#{name}' do |req|
        #{singular} = db.add('#{name}', req.json_body)
        json(#{singular}, http_status: '201 Created')
      end

      put '/#{name}/:id' do |req|
        updated_#{singular} = db.update('#{name}', req.params['id'].to_i, req.json_body)
        next not_found('#{singular.capitalize} not found') unless updated_#{singular}

        json(updated_#{singular})
      end

      delete '/#{name}/:id' do |req|
        if db.delete('#{name}', req.params['id'].to_i)
          no_content
        else
          not_found('#{singular.capitalize} not found')
        end
      end
    RUBY
  end

  def build_migration_template(name, fields)
    lines = ["Yanikasu.migration do", "  create_table :#{name} do"]
    fields.each do |field_name, type|
      lines << "    #{type} :#{field_name}"
    end
    lines << '  end'
    lines << 'end'
    lines.join("\n") + "\n"
  end

  def inject_before_final_end(content, block)
    stripped = content.rstrip
    raise ArgumentError, '設定ファイルの末尾に end が必要です' unless stripped.end_with?('end')

    stripped.sub(/end\z/, "#{block}end\n")
  end

  def valid_field_type?(type)
    %w[string text integer boolean float].include?(type)
  end

  def singularize(name)
    name.end_with?('s') ? name[0..-2] : name
  end

  def ensure_directory(path)
    Dir.mkdir(File.join(@cwd, path)) unless Dir.exist?(File.join(@cwd, path))
  end

  def write_if_missing(path, content)
    full_path = File.join(@cwd, path)
    return if File.exist?(full_path)

    File.write(full_path, content)
  end

  def valid_generator_name?(name)
    !name.nil? && /\A[a-z0-9_]+\z/.match?(name)
  end

  def print_usage
    @stderr.puts 'usage: ruby bin/yanikasu init | generate migration NAME | generate resource NAME field:type'
  end
end
