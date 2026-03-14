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
    @stderr.puts 'usage: ruby bin/yanikasu init | generate migration NAME'
  end
end
