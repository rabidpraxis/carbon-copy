require 'carbon-copy/cache_server'
require 'carbon-copy/request_cacher'

#### CarbonCopy
#
# CarbonCopy is a simple server that sits between your outbound api requests
# and your file system. It was created in response to a frustration when
# developing frontend applications on untested backends. CarbonCopy stores your
# requests locally so if a server stops responding, or is too slow to test on,
# you can rely on cached data instead of making an http reqest for each
# refresh.
#

module CarbonCopy
  VERSION = '0.0.2'

  # connect all teh pieces
  class CarbonCopy
    attr_writer :request_cacher, :port

    def run
      CacheServer.new(port, request_cacher).run
    end

    # default to built in request cacher with current path as the request cache
    # location
    def request_cacher
      @request_cacher || RequestCacher.new(Dir.pwd)
    end

    # default to port 7979
    def port
      @port || 7979
    end
  end
end
