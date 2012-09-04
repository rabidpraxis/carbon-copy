require 'digest/md5'

module CarbonCopy
  class HTTPCacher
    attr_reader :base_dir

    def initialize(base_dir = Dir.pwd)
      @base_dir = base_dir
    end

    #--------------------------------------------------------------------------
    # Setup cache directory
    #--------------------------------------------------------------------------
    def cache_dir
      "#{base_dir}/.request_cache"
    end

    #--------------------------------------------------------------------------
    # Determine final path
    #--------------------------------------------------------------------------
    def path(parsed)
      uri = ( parsed.uri == '/' ) ? '' : parsed.uri.gsub("\/", "_")
      hash = Digest::MD5.new << parsed.header_str
      #---  Cache directory structure  ----------------------------------------
      """
        #{cache_dir}/
          #{parsed.host}/
            #{parsed.verb.downcase}
            #{uri}_
            #{hash}
      """.gsub(/\n|\s/, '')
    end

    #--------------------------------------------------------------------------
    # Ensure cached directories are created
    #--------------------------------------------------------------------------
    def verify_cached_dir(parsed)
      Dir.mkdir(cache_dir) unless File.exists?(cache_dir)
      host_cache = "#{cache_dir}/#{parsed.host}"
      Dir.mkdir(host_cache) unless File.exists?(host_cache)
    end

    def get_response(parsed)
      a = TCPSocket.new(parsed.host, parsed.port)
      a.write(parsed.response)

      #---  Pull request data  ------------------------------------------------
      content_len = nil
      buff = ""
      loop do
        line = a.readline
        buff += line
        if line =~ /^Content-Length:\s+(\d+)\s*$/
          content_len = $1.to_i
        end
        break if line.strip.empty?
      end

      #---  Pull response  ----------------------------------------------------
      if content_len
        buff += a.read(content_len)
      else
        loop do
          if a.eof? || line = a.readline || line.strip.empty?
            break
          end
          buff += line
        end
      end
      a.close

      buff
    end

    def connect(parsed)
      verify_cached_dir(parsed)
      cached_path = path(parsed)

      if File.exists?(cached_path) && !File.zero?(cached_path)
        puts "Getting file #{cached_path} from cache"
        IO.read( cached_path )
      else
        resp = get_response(parsed)
        File.open( cached_path, 'w' ) do |f|
          f.puts resp
        end
        resp
      end
    end
  end
end
