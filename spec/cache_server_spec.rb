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
    
    describe 'just host' do
      let(:request) { create_host_IO("GET /apple.com HTTP/1.1\n") }

      specify { req[:host].should eq('apple.com') }
      specify { req[:uri].should  eq('/') }
    end

    describe 'host with port' do
      let(:request) { create_host_IO("GET /apple.com:3000 HTTP/1.1\n") }

      specify { req[:port].should eq('3000') }
      specify { req[:host].should eq('apple.com') }
      specify { req[:url].should  eq('apple.com') }
      specify { req[:uri].should  eq('/') }
    end

    describe 'host with path' do
      let(:request) { create_host_IO("GET /apple.com/google/face/ HTTP/1.1\n") }

      specify { req[:verb].should        eq("GET") }
      specify { req[:url].should         eq('apple.com/google/face/') }
      specify { req[:version].should     eq('1.1') }
      specify { req[:host].should        eq('apple.com') }
      specify { req[:uri].should         eq('/google/face/') }
      specify { req[:request_str].should eq("GET /google/face/? HTTP/1.1\r") }
    end
  end

  def create_host_IO(host)
    req = StringIO.new
    host.split("\n").each do |host|
      req << "#{host}\n"
    end
    req.rewind
    req
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
