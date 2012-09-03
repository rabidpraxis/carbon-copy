require 'socket'
require 'open-uri'
require 'openssl'
require 'carbon-copy/http_cacher'

module CarbonCopy
  class CacheServer

    def run(port)
      webserver = TCPServer.new('127.0.0.1', port)
      puts "Running Carbon Copy on localhost port #{port}"
      while (session = webserver.accept)
        Thread.new(session, &method(:handle))
      end
    end

    def parse_request(session)
      request = session.readline

      p = {}
      #---  Initial host/uri information  -------------------------------------
      p[:verb]    = request.slice!(/^\w+\s/).strip
      p[:host]    = request.slice!(/^\/[^\/: ]+/)[1..-1]
      p[:port]    = request.slice!(/^:(\S+)/)

      p[:port]    = ( p[:port].nil? ) ? '80' : p[:port][1..-1] # Remove the colon

      p[:path]    = request.slice!(/^(\S)+/)
      p[:version] = request[/HTTP\/(1\.\d)\s*$/, 1]
      p[:url]     = "#{p[:host]}#{p[:path]}"
      p[:uri]     = "#{p[:path] || '/'}"

      uri = URI::parse(p[:uri])
      p[:request_str] = "#{p[:verb]} #{uri.path}?#{uri.query} HTTP/#{p[:version]}\r"

      #---  Header and final response text  -----------------------------------
      p[:headers] = parse_headers(session)
      
      #---  Update header info  -----------------------------------------------
      p[:headers]["Host"] = p[:host]

      p[:header_str] = p[:headers].map{|a, b| "#{a}: #{b}"}.join("\r\n")
      p[:response] = "#{p[:request_str]}\n#{p[:header_str]}\r\n\r\n"

      p
    end
    
    def parse_headers(request)
      header = {}
      unless request.eof?
        loop do
          line = request.readline
          if line.strip.empty?
            break
          end

          /^(\S+): ([^\r\n]+)/.match(line)
          header[$1] = $2
        end
      end
      header
    end

    def handle(session)
      begin
        req = parse_request(session)
        resp = HTTPCacher.new.connect(req)
        session.write(resp)
        session.close
      rescue => e
        p e.message
        p e.backtrace
      end
    end
  end
end
