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

    def ssh_run(port)
      begin
        server = TCPServer.new(port)
        cert, priv = create_cert
        context = OpenSSL::SSL::SSLContext.new
        context.cert = OpenSSL::X509::Certificate.new(cert)
        context.key = OpenSSL::PKey::RSA.new(priv)
        ssl_server = OpenSSL::SSL::SSLServer.new(server, context)

        while (session = ssl_server.accept)
          Thread.new(session, &method(:handle))
        end
      rescue => e
        p e.message
        p e.backtrace
      end
    end

    def create_cert
      key = OpenSSL::PKey::RSA.new(1024)
      public_key = key.public_key

      subject = "/C=BE/O=Test/OU=Test/CN=Test"

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.now
      cert.not_after = Time.now + 365 * 24 * 60 * 60
      cert.public_key = public_key
      cert.serial = 0x0
      cert.version = 2

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.extensions = [
        ef.create_extension("basicConstraints","CA:TRUE", true),
        ef.create_extension("subjectKeyIdentifier", "hash"),
      ]
      cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                             "keyid:always,issuer:always")

      cert.sign key, OpenSSL::Digest::SHA1.new

      [cert.to_pem, key]
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

    def ssl_handle(session)
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
