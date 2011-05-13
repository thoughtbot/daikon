$fake_radish_registry = {:get => {}, :post => {}, :any => {}}
$fake_radish_requests = []

module FakeRadish
 module Server

   def post_init
     @data_received = ""
   end

   def receive_data data
     $stdout.write(data)
     @data_received << data
     method, path = parse_http_info
     save_request(data)
     puts data
     puts response_for(method, path)
     send_data response_for(method, path)
     close_connection_after_writing
     return true
   end

   def save_request(data)
     header, body = data.split("\r\n\r\n")
     request_str, *header_lines = header.split("\r\n")
     headers = {}
     headers_lines.each do |header_line|
       key, value = headler_line.split(/:\s+/)
       headers[key] = value
     end
     method, path = parse_http_info
     $fake_radish_requests << {:method => method, :body => body, :headers => headers}
   end

   def parse_method(method)
     method.downcase.to_sym
   end

   def parse_http_info
     @data_received.split(/\s+/)[0,2]
   end

   def received_requests
     @received_requests ||= {:get => {}, :post => {}, :any => {}}
   end

   def response_for(method, path)
     method = parse_method(method)
     received_requests[method][path] = received_requests[:any][path] = true
     response = $fake_radish_registry[method][path] || $fake_radish_registry[:any][path]
     if response
       raw_response = "HTTP/1.1 #{response.status[0]} #{response.status[1]}\r\n"
       raw_response << response.headers.map{|key, value| "#{key}: #{value}"}.join("\r\n")
       raw_response << "\r\n\r\n"
       raw_response << response.body
       raw_response
     else
       body = "Not Found"
       headers = {
         :Date => Time.now,
         :Server => "FakeRadish Server",
         :"Last-Modified" => Time.now,
         :"Accept-Ranges" => "bytes",
         :"Content-Length" => body.length,
         :Vary => "Accept-Encoding",
         :Connection => "close",
         :"Content-Type" => "text/html"
       }
       raw_response = "HTTP/1.1 404 Not Found\r\n"
       raw_response << headers.map{|key, value| "#{key}: #{value}"}.join("\r\n")
       raw_response << "\r\n\r\n"
       raw_response << body
       raw_response
     end
   end

 end

 class Stub
   def initialize(method, path)
     $fake_radish_registry[method][path] = self
   end

   def body
     @options[:body] || ""
   end

   def default_headers
     {
       :Date => Time.now,
       :Server => "FakeRadish Server",
       :"Last-Modified" => Time.now,
       :"Accept-Ranges" => "bytes",
       :"Content-Length" => body.length,
       :Vary => "Accept-Encoding",
       :Connection => "close",
       :"Content-Type" => "text/html"
     }
   end

   def headers
     default_headers.merge(@options[:headers] || {})
   end

   def status
     [@options[:status], "OK"]
   end

   def to_return options = {}
     @options = options
   end

   def to_timeout

   end
 end

 module Matchers
   def have_requested(method, uri)
     FakeRadish::FakeRadishMatcher.new(method, uri)
   end
 end

 class FakeRadishMatcher
   def initialize(method, uri)
     @method = method
     @uri = uri
   end

   def with(options = {}, &block)
     @options = options
     @block   = block
     self
   end

   def matches?(fake_radish)
     puts $fake_radish_requests.inspect
   end

   def failure_message
     "Request not matched"
   end

   def negative_failure_message
     "Request matched when it should not have been"
   end

   def does_not_match?(fake_radish)
     puts "SIGH"
   end
 end
end

def stub_request(method, path)
  puts "STUBBING: #{method} #{path}"
  FakeRadish::Stub.new(method, path)
end

Thread.new do
  EventMachine::run {
    EventMachine::start_server("0.0.0.0", 8090, FakeRadish::Server)
  }
end
