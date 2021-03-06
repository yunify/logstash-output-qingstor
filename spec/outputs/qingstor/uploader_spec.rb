# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/qingstor/uploader'
require 'logstash/outputs/qingstor/temporary_file'
require 'qingstor/sdk'
require 'stud/temporary'
require 'fileutils'
require_relative '../qs_access_helper'

describe LogStash::Outputs::Qingstor::Uploader do
  subject { described_class.new(bucket, logger, threadpool) }

  let(:bucket) { qs_init_bucket }
  let(:key) { 'foobar' }
  let(:tmp_file) { Stud::Temporary.file }
  let(:tmp_path) { tmp_file.path }
  let(:logger) { spy(:logger) }

  let(:threadpool) do
    Concurrent::ThreadPoolExecutor.new(:min_threads => 1,
                                       :max_threads => 4,
                                       :max_queue => 1,
                                       :fallback_policy => :caller_runs)
  end

  let(:file) do
    f = LogStash::Outputs::Qingstor::TemporaryFile.new(key, tmp_file, tmp_path)
    f.write('May the code be with you!')
    f.fsync
    f
  end

  before(:all) do
    clean_remote_files
  end

  after(:each) do
    delete_remote_file key
    FileUtils.rm_r(tmp_file)
  end

  it 'upload file to the qingstor bucket' do
    subject.upload(file)
    expect(list_remote_file.size).to eq(1)
  end

  it 'async upload file to qingstor' do
    subject.upload_async(file)
    sleep 2
    expect(list_remote_file.size).to eq(1)
  end

  it 'execute a callback when the upload is complete' do
    callback = proc { |f| }
    expect(callback).to receive(:call).with(file)
    subject.upload(file, :on_complete => callback)
  end
end
