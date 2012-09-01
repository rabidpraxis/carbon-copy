require File.expand_path('../../lib/carbon-copy', __FILE__)
require 'open-uri'
require 'net/http'

describe CarbonCopy::CacheServer do
  describe '#parse_headers' do
    let(:rs) { CarbonCopy::CacheServer.new }
    
    it 'should parse easy header strings' do
      st = StringIO.new
      st << "TestHeader: Header Result"
      st << "\r\n\r\n"
      st.rewind
      rs.parse_headers(st).should eq({"TestHeader" => "Header Result"})
    end

    it 'should parse multi-line headers' do
      st = StringIO.new
      st << "TestHeader: Header Result\n"
      st << "TestHeaders: Header Result"
      st << "\r\n\r\n"
      st.rewind
      rs.parse_headers(st).should eq({
        "TestHeader" => "Header Result",
        "TestHeaders" => "Header Result"
      })
    end
  end

  describe '#parse_request' do
    let(:rs) { CarbonCopy::CacheServer.new }
    let(:req) { rs.parse_request(request) }
    
    describe 'host with path' do
      let(:request) { 
        req = StringIO.new << "GET /apple.com/google/face/ HTTP/1.1\n"
        req.rewind 
        req
      }

      it 'verb' do
        req[:verb].should eq("GET")
      end

      it 'url with path' do
        req[:url].should eq('apple.com/google/face/')
      end

      it 'version' do
        req[:version].should eq('1.1')
      end

      it 'host' do
        req[:host].should eq('apple.com')
      end

      it 'uri' do
        req[:uri].should eq('/google/face/')
      end

      it 'request_str' do
        req[:request_str].should eq("GET /google/face/? HTTP/1.1\r")
      end
    end

    describe 'just host' do
      let(:request) { 
        req = StringIO.new << "GET /apple.com HTTP/1.1\n"
        req.rewind 
        req
      }
      it 'host' do
        req[:host].should eq('apple.com')
      end

      it 'uri' do
        req[:uri].should eq('/')
      end
    end

  end

  describe '#handle' do
    before(:all) do
      Thread.new do
        CarbonCopy::CacheServer.new.run(7979)
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

def get(url)
  Net::HTTP.get_response(URI.parse(url))
end
