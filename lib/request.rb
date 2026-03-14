# lib/request.rb
require 'json'
require 'stringio'
require 'uri'

class Request
  attr_reader :method, :path, :headers, :body, :params

  def initialize(socket)
    @headers = {}
    read_request(socket)
  end

  def self.from_raw(raw_request)
    new(StringIO.new(raw_request))
  end

  def json_body
    return {} if @body.nil? || @body.empty?

    JSON.parse(@body)
  end

  private

  def read_request(socket)
    request_line = socket.gets
    raise ArgumentError, 'Empty request' if request_line.nil?

    request_line = request_line.strip
    @method, full_path, @version = request_line.split
    parse_headers(socket)
    @path, query_string = full_path.split('?')
    @params = parse_query(query_string)
    @body = read_body(socket) if @headers['Content-Length']
  end

  def parse_headers(socket)
    while (raw_line = socket.gets)
      line = raw_line.strip
      break if line == ''

      key, value = line.split(': ', 2)
      @headers[key] = value
    end
  end

  def parse_query(query_string)
    return {} unless query_string

    URI.decode_www_form(query_string).to_h
  end

  def read_body(socket)
    content_length = @headers['Content-Length'].to_i
    socket.read(content_length)
  end
end
