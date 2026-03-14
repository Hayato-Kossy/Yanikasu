# lib/yanikasu.rb
# ルーティングはcliからconfig/routes.rbに書き込み、読み込むように変更したい
# ハンドラーも分離したい
require 'socket'
require 'json'
require_relative 'router'
require_relative 'request'
require_relative 'response'
require_relative 'db'
require_relative '../middleware/cors'

module Yanikasu
  class MigrationContext
    def initialize(db)
      @db = db
    end

    def execute(sql, binds = [])
      @db.execute(sql, binds)
    end
  end

  class SchemaDSL
    def initialize
      @schema = {}
    end

    def collection(name, &block)
      builder = CollectionDSL.new
      builder.instance_eval(&block)
      @schema[name.to_s] = builder.to_h
    end

    def to_h
      @schema
    end
  end

  class CollectionDSL
    def initialize
      @attributes = {}
    end

    %i[string text integer boolean float].each do |type|
      define_method(type) do |name|
        @attributes[name.to_s] = type
      end
    end

    def to_h
      @attributes
    end
  end

  def self.handle_options_request(socket)
    Response.new(status: '200 OK', headers: CorsMiddleware.apply, body: '').send(socket)
  end

  def self.start_server(host: nil, port: nil, db_name: nil, env: ENV)
    config = server_config(env: env, host: host, port: port, db_name: db_name)
    server = TCPServer.new(config[:host], config[:port])
    db = DB.new(config[:db_name], schema: load_schema)
    run_pending_migrations(db, path: config[:migrations_path])
    router = Router.new
    load_routes(router)
    puts "Server is running on http://#{config[:host]}:#{config[:port]}/"
    loop do
      socket = server.accept
      begin
        request = Request.new(socket)
        process_request(socket, request, router, db)
      rescue ArgumentError => e
        Response.new(
          status: '400 Bad Request',
          headers: CorsMiddleware.apply('Content-Type' => 'application/json'),
          body: { error: e.message }
        ).send(socket)
      ensure
        socket.close unless socket.closed?
      end
    end
  end

  def self.process_request(socket, request, router, db)
    if request.method == 'OPTIONS'
      handle_options_request(socket)
      return
    end

    response = router.find_route_and_execute(request, db)
    resp = Response.new(
      status: response[:status],
      headers: CorsMiddleware.apply(response[:headers] || {}),
      body: response[:body] || ''
    )
    resp.send(socket)
    puts response[:body]
  rescue JSON::ParserError
    Response.new(
      status: '400 Bad Request',
      headers: CorsMiddleware.apply('Content-Type' => 'application/json'),
      body: { error: 'Invalid JSON body' }
    ).send(socket)
  rescue StandardError => e
    Response.new(
      status: '500 Internal Server Error',
      headers: CorsMiddleware.apply('Content-Type' => 'application/json'),
      body: { error: 'Internal Server Error', detail: e.message }
    ).send(socket)
  end

  def self.draw_routes(&block)
    @routes_block = block
  end

  def self.define_schema(&block)
    builder = SchemaDSL.new
    builder.instance_eval(&block)
    @schema_definition = builder.to_h
  end

  def self.migration(version = nil, &block)
    @migration_definition = { version: version, block: block }
  end

  def self.load_routes(router)
    @routes_block = nil
    load File.expand_path('../config/routes.rb', __dir__)
    raise ArgumentError, 'No routes defined in config/routes.rb' unless @routes_block

    router.draw(&@routes_block)
  end

  def self.load_schema
    @schema_definition = nil
    schema_file = File.expand_path('../config/schema.rb', __dir__)
    load schema_file if File.exist?(schema_file)
    @schema_definition || {}
  end

  def self.server_config(env: ENV, host: nil, port: nil, db_name: nil)
    {
      host: host || env.fetch('YANIKASU_HOST', 'localhost'),
      port: Integer(port || env.fetch('YANIKASU_PORT', '3000')),
      db_name: db_name || env.fetch('YANIKASU_DB_PATH', 'db.sqlite3'),
      migrations_path: env.fetch('YANIKASU_MIGRATIONS_PATH', File.expand_path('../migrations', __dir__))
    }
  end

  def self.run_pending_migrations(db, path: default_migrations_path)
    ensure_migration_table(db)
    applied_versions = db.execute('SELECT version FROM schema_migrations ORDER BY version').map do |row|
      row['version'] || row[0]
    end

    migration_files(path).each do |file|
      definition = load_migration(file)
      version = definition[:version]
      next if applied_versions.include?(version)

      db.transaction do
        MigrationContext.new(db).instance_eval(&definition[:block])
        db.execute('INSERT INTO schema_migrations (version) VALUES (?)', [version])
      end
    end
  end

  def self.default_migrations_path
    File.expand_path('../migrations', __dir__)
  end

  def self.migration_files(path)
    return [] unless Dir.exist?(path)

    Dir[File.join(path, '*.rb')].sort
  end

  def self.load_migration(path)
    @migration_definition = nil
    load path
    raise ArgumentError, "No migration defined in #{path}" unless @migration_definition

    {
      version: (@migration_definition[:version] || File.basename(path, '.rb')),
      block: @migration_definition[:block]
    }
  end

  def self.ensure_migration_table(db)
    db.execute <<~SQL
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version TEXT PRIMARY KEY
      );
    SQL
  end
end
