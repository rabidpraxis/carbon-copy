require 'spec_helper'
require 'open-uri'
require 'net/http'
require 'sinatra/base'
require 'rest-client'

class TestApp < Sinatra::Base
  get '/awesome' do
    'This is an awesome get request!'
  end
  
  options '/awesome' do
    'This is an awesome options request!'
  end
end

module CarbonCopy
describe CarbonCopy do

  describe '#handle' do
    before(:all) do
      @cache_thread = Thread.new do
        carbon_copy = CarbonCopy.new
        carbon_copy.request_cacher = RequestCacher.new(support_path)
        carbon_copy.port = 7979
        carbon_copy.run
      end

      @sinatra_thread = Thread.new do
        TestApp.run! host: 'localhost', port: 9898
      end
      sleep 1 # to allow for sinatra to boot
    end

    after(:all) do
      @cache_thread.kill
      @sinatra_thread.kill
    end

    it 'caches get request' do
      url = 'localhost:9898/awesome'
      o_req = RestClient.get("http://#{url}").to_str
      req =   RestClient.get("http://localhost:7979/#{url}").to_str
      req.should eq(o_req)
    end

    it 'caches options request' do
      url = 'localhost:9898/awesome'
      o_req = RestClient.options("http://#{url}").to_str
      req =   RestClient.options("http://localhost:7979/#{url}").to_str
      req.should eq(o_req)
    end

    def support_path
      File.expand_path('../support', __FILE__)
    end
  end
end
end
