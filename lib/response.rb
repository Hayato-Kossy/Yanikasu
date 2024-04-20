# lib/response.rb
# CORSは暫定でここに書いているが、middlewareに移動するTod
class Response
  attr_accessor :status, :headers, :body

  def initialize(status: '200 OK', headers: {}, body: '')
    @status = status
    @headers = headers
    self.body = body 
  end

  def body=(value)
    @body = value.is_a?(String) ? value : JSON.generate(value)
  end

  def send(socket)
      cors_headers = {
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type, Authorization"
      }
      response_headers = "HTTP/1.1 #{@status}\r\nContent-Type: application/json\r\n"
      cors_headers.each { |key, value| response_headers += "#{key}: #{value}\r\n" }
      response_headers += "Content-Length: #{body.bytesize}\r\n\r\n"
  
      socket.print response_headers
      socket.print body 
  end  
end