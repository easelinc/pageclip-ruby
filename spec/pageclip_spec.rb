require 'spec_helper'

describe 'Pageclip' do
  describe 'configuring' do
    it 'can set the api key'
    it 'can set the job defaults'
    it 'can set the logger'
  end
  describe 'taking a screenshot' do
    context 'with configuration' do
      it 'can request with just a url'
      it 'can request with a url and options'
      it 'handles timeouts'
      it 'handles unauthorized errors'
      it 'handles rate limit errors'
    end
    context 'with default job options' do
      it 'can request with just a url'
      it 'can override a property'
    end
    context 'with a logger' do
      it 'can request with just a url'
    end
  end
end
