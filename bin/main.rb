# main.rb エントリーポイント
require_relative '../lib/yanikasu'

begin
  Yanikasu.start_server
rescue Interrupt
  puts "\nServer stopped."
rescue StandardError => e
  puts "Exception occurred: #{e.message}"
  puts e.backtrace
end
