# lib/response.rb
require 'json'

class Response
  attr_accessor :status, :headers, :body

  def initialize(status: '200 OK', headers: {}, body: '')
    @status = status
    @headers = headers.dup
    self.body = body
  end

  def body=(value)
    @headers['Content-Type'] ||= value.is_a?(String) ? 'text/plain' : 'application/json'
    @body = value.is_a?(String) ? value : JSON.generate(value)
  end

  def send(socket)
    merged_headers = @headers.merge('Content-Length' => body.bytesize.to_s)
    response_headers = "HTTP/1.1 #{@status}\r\n"
    merged_headers.each { |key, value| response_headers += "#{key}: #{value}\r\n" }
    response_headers += "\r\n"

    socket.print response_headers
    socket.print body
  end
end
