require 'logger'
require 'spec_helper'

describe 'Pageclip::Configuration' do
  subject do
    Pageclip::Configuration.new
  end

  it 'can set the api key' do
    subject.api_key = 'asdf'
    subject.api_key.should eq('asdf')
  end

  it 'can set the job defaults' do
    subject.job_defaults = { :timeout => 30 }
    subject.job_defaults[:timeout].should eq(30)
  end

  it 'can set the logger' do
    subject.logger = Logger.new(STDOUT)
    subject.logger.should respond_to(:info)
  end
end
