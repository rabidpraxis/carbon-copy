require File.expand_path('../../lib/carbon-copy', __FILE__)
require 'digest/md5'

describe CarbonCopy::HTTPCacher do
  let(:cacher) { CarbonCopy::HTTPCacher.new }
  let(:parsed) {
    {
      verb: 'GET',
      url: 'gist.github.com/74107',
      host: 'gist.github.com',
      version: '1.1',
      uri: '/74107',
      header_str: 'Test Header: Test Result'
    }
  }
  it 'should have path with url' do
    hash = Digest::MD5.new << parsed[:header_str]
    cacher.path(parsed).should match(/\.request_cache\/gist\.github\.com\/get_74107_#{hash}/)
  end

  it 'should reflect no path' do
    hash = Digest::MD5.new << parsed[:header_str]
    parsed[:url] = 'gist.github.com'
    parsed[:uri] = '/'
    cacher.path(parsed).should match(/\.request_cache\/gist\.github\.com\/get_#{hash}/)
  end
end
