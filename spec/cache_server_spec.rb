require 'spec_helper'
require 'open-uri'
require 'net/http'

module CarbonCopy
describe CacheServer do
  describe '#handle' do
    before(:all) do
      Thread.new do
        CacheServer.new.run(7979)
      end
    end

    it 'caches google.com simple get request' do
      url = 'www.apple.com'
      o_req = get("http://#{url}").body
      req   = get("http://localhost:7979/#{url}").body
      req.should eq(o_req)
    end
  end
end
end

def get(url)
  Net::HTTP.get_response(URI.parse(url))
end
