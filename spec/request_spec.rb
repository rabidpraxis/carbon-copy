require "spec_helper"
require "carbon-copy/request"

module CarbonCopy
  describe Request do
    describe "#parse_headers" do
      let(:rs) { Request.new(double) }

      it "should parse easy header strings" do
        st = StringIO.new
        st << "TestHeader: Header Result"
        st << "\r\n\r\n"
        st.rewind
        rs.parse_headers(st).should eq({"TestHeader" => "Header Result"})
      end

      it "should parse multi-line headers" do
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

    describe "#parse" do
      let(:rs) { Request.new(request).parse }

      describe "just host" do
        let(:request) { create_host_IO("GET /apple.com HTTP/1.1\n") }

        specify { rs.host.should eq("apple.com") }
        specify { rs.uri.should eq("/") }
      end

      describe "host with port" do
        let(:request) { create_host_IO("GET /apple.com:3000 HTTP/1.1\n") }

        specify { rs.port.should eq("3000") }
        specify { rs.host.should eq("apple.com") }
        specify { rs.url.should eq("apple.com") }
        specify { rs.uri.should eq("/") }
      end

      describe "host with port and path" do
        let(:request) { create_host_IO("GET /apple.com:18/awesome HTTP/1.1\n") }

        specify { rs.port.should eq("18") }
        specify { rs.host.should eq("apple.com") }
        specify { rs.url.should eq("apple.com/awesome") }
        specify { rs.uri.should eq("/awesome") }
      end

      describe "host with get string" do
        let(:request) { create_host_IO("POST /fazebook.com/google?p=test HTTP/1.1\n") }

        specify { rs.verb.should eq("POST") }
        specify { rs.port.should eq("80") }
        specify { rs.url.should eq("fazebook.com/google?p=test") }
        specify { rs.request_str.should eq("POST /google?p=test HTTP/1.1\r") }
      end

      describe "host with path" do
        let(:request) { create_host_IO("GET /apple.com/google/face/ HTTP/1.1\n") }

        specify { rs.verb.should eq("GET") }
        specify { rs.port.should eq("80") }
        specify { rs.url.should eq("apple.com/google/face/") }
        specify { rs.version.should eq("1.1") }
        specify { rs.host.should eq("apple.com") }
        specify { rs.uri.should eq("/google/face/") }
        specify { rs.request_str.should eq("GET /google/face/? HTTP/1.1\r") }
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
  end
end
