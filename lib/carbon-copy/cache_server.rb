require 'socket'
require 'open-uri'
require 'openssl'
require 'pry'
require 'pp'
require 'webrick/ssl'
require 'carbon-copy/http_cacher'

module CarbonCopy
  class CacheServer

    def run(port)
      webserver = TCPServer.new('127.0.0.1', port)
      while (session = webserver.accept)
        Thread.new(session, &method(:handle))
      end
    end

    def parse_request(session)
      request = session.readline

      parsed = {}
      #---  Initial host/uri information  -------------------------------------
      parsed[:verb]    = request[/^\w+/]
      parsed[:url]     = request[/^#{parsed[:verb]}\s+\/(\S+)/, 1]
      parsed[:host]    = request[/^#{parsed[:verb]}\s+\/([^\/ ]+)/, 1]
      parsed[:version] = request[/HTTP\/(1\.\d)\s*$/, 1]
      parsed[:uri]     = request[/^#{parsed[:verb]}\s+\/#{parsed[:host]}(\S+)\s+HTTP\/#{parsed[:version]}/, 1] || '/'

      uri = URI::parse(parsed[:uri])
      parsed[:request_str] = "#{parsed[:verb]} #{uri.path}?#{uri.query} HTTP/#{parsed[:version]}\r"

      #---  Header and final response text  -----------------------------------
      parsed[:headers] = parse_headers(session)
      
      #---  Update header info  -----------------------------------------------
      parsed[:headers]["Host"]   = parsed[:host]

      parsed[:header_str] = parsed[:headers].map{|a, b| "#{a}: #{b}"}.join("\r\n")
      parsed[:response] = "#{parsed[:request_str]}\n#{parsed[:header_str]}\r\n\r\n"

      parsed
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
