require 'socket'
require 'openssl'
require 'carbon-copy/request_cacher'

module CarbonCopy
  class CacheServer

    def run(port)
      webserver = TCPServer.new('127.0.0.1', port)
      puts "Running Carbon Copy on localhost port #{port}"
      while (session = webserver.accept)
        Thread.new(session, &method(:handle))
      end
    end

    def handle(session)
      begin
        req = Request.new(session).parse
        resp = RequestCacher.new(cache_dir).connect(req)
        session.write(resp)
        session.close
      rescue => e
        p e.message
        p e.backtrace
      end
    end
  end
end
