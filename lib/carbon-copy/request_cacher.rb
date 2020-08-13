require "digest/md5"
require "fileutils"

module CarbonCopy
  class RequestCacher
    attr_reader :base_dir

    def initialize(base_dir)
      @base_dir = base_dir
    end

    # Setup cache directory
    def cache_dir
      "#{@base_dir}/.request_cache"
    end

    # Determine final path
    def path(request)
      uri = request.uri == "/" ? "" : request.uri.tr("\/", "_")
      hash = Digest::MD5.new << request.header_str
      # Cache directory structure
      """
        #{cache_dir}/
          #{request.host}/
            #{request.verb.downcase}
            #{uri}_
            #{hash}
      """.gsub(/\n|\s/, "")
    end

    # Ensure cached directories are created
    def verify_cached_dir(request)
      FileUtils.mkdir_p(cache_dir) unless File.exist?(cache_dir)
      host_cache = "#{cache_dir}/#{request.host}"
      FileUtils.mkdir_p(host_cache) unless File.exist?(host_cache)
    end

    def get_response(request)
      a = TCPSocket.new(request.host, request.port)
      a.write(request.request)

      # Pull request data
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

      # Pull response
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

    def connect(request)
      verify_cached_dir(request)
      cached_path = path(request)

      if File.exist?(cached_path) && !File.zero?(cached_path)
        puts "Getting file #{cached_path} from cache"
        IO.read(cached_path)
      else
        resp = get_response(request)
        File.open(cached_path, "w") do |f|
          f.puts resp
        end
        resp
      end
    end
  end
end
