require 'socket'
require 'openssl'
require 'carbon-copy/request_cacher'

module CarbonCopy
  class CacheServer

    def initialize(port, request_cacher)
      @port           = port
      @request_cacher = request_cacher
    end

    def run
      webserver = TCPServer.new('127.0.0.1', @port)
      puts "Running Carbon Copy on localhost port #{@port}"
      while (session = webserver.accept)
        Thread.new(session, &method(:handle))
      end
    end

    def handle(session)
      begin
        request = Request.new(session)
        request.parse
        response = @request_cacher.connect(request)
        session.write(response)
        session.close
      rescue => e
        p e.message
        p e.backtrace
      end
    end
  end
end
