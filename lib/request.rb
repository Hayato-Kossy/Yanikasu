# lib/request.rb
require 'json'

class Request
  attr_reader :method, :path, :headers, :body, :params

  def initialize(socket)
    @headers = {}
    read_request(socket)
  end
  def json_body
    JSON.parse(@body)
  end
  private

  def read_request(socket)
    request_line = socket.gets.strip
    @method, full_path, @version = request_line.split
    parse_headers(socket)
    @path, query_string = full_path.split('?')
    @params = parse_query(query_string)
    @body = read_body(socket) if @headers['Content-Length']
  end

  def parse_headers(socket)
    while (line = socket.gets.strip) != ''
      key, value = line.split(': ', 2)
      @headers[key] = value
    end
  end

  def parse_query(query_string)
    return {} unless query_string
    query_string.split('&').map { |pair| pair.split('=') }.to_h
  end

  def read_body(socket)
    content_length = @headers['Content-Length'].to_i
    socket.read(content_length)
  end
end