# lib/responce.rb
class Response
  attr_accessor :status, :headers, :body

  def initialize(status: '200 OK', headers: {}, body: '')
    @status = status
    @headers = headers
    @body = body
  end

  def send(socket)
    socket.print "HTTP/1.1 #{@status}\r\n"
    @headers.each { |key, value| socket.print "#{key}: #{value}\r\n" }
    socket.print "\r\n"
    socket.print @body
  end
end