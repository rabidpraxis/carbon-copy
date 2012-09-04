require 'spec_helper'
require 'digest/md5'
require 'ostruct'

module CarbonCopy
describe HTTPCacher do
  let(:cacher) { HTTPCacher.new }
  let(:parsed) {
    a = OpenStruct.new
    a.verb = 'GET'
    a.url = 'gist.github.com/74107'
    a.host = 'gist.github.com'
    a.version = '1.1'
    a.uri = '/74107'
    a.header_str = 'Test Header = Test Result'
    a
  }
  it 'should have path with url' do
    hash = Digest::MD5.new << parsed.header_str
    cacher.path(parsed).should match(/\.request_cache\/gist\.github\.com\/get_74107_#{hash}/)
  end

  it 'should reflect no path' do
    hash = Digest::MD5.new << parsed.header_str
    parsed.url = 'gist.github.com'
    parsed.uri = '/'
    cacher.path(parsed).should match(/\.request_cache\/gist\.github\.com\/get_#{hash}/)
  end
end
end
