require 'open-uri'

module CarbonCopy
  class Request
    attr_accessor :verb, :host, :port, :path, :version, :url, :uri,
      :request_str, :headers, :header_str, :response

    def initialize(session)
      @session = session
    end

    def parse
      request = @session.readline

      #---  Initial host/uri information  -------------------------------------
      @verb    = request.slice!(/^\w+\s/).strip
      @host    = request.slice!(/^\/[^\/: ]+/)[1..-1]
      @port    = request.slice!(/^:(\d+)/)

      @port    = ( @port.nil? ) ? '80' : @port[1..-1] # Remove the colon

      @path    = request.slice!(/^(\S)+/)
      @version = request[/HTTP\/(1\.\d)\s*$/, 1]
      @url     = "#{@host}#{@path}"
      @uri     = "#{@path || '/'}"

      uri = URI::parse(@uri)
      @request_str = "#{@verb} #{uri.path}?#{uri.query} HTTP/#{@version}\r"

      #---  Header and final response text  -----------------------------------
      @headers = parse_headers(@session)
      
      #---  Update header info  -----------------------------------------------
      @headers["Host"] = @host

      @header_str = @headers.map{|a, b| "#{a}: #{b}"}.join("\r\n")
      @request = "#{@request_str}\n#{@header_str}\r\n\r\n"

      self
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
  end
end
