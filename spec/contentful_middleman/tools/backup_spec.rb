require 'spec_helper'

class DoBackupDouble
  include ContentfulMiddleman::Tools::Backup::InstanceMethods
end

describe ContentfulMiddleman::Tools::NullBackup do
  describe 'instance methods' do
    describe 'do nothing' do
      it '#restore' do
        expect(subject.restore).to eq nil
      end

      it '#destroy' do
        expect(subject.destroy).to eq nil
      end
    end
  end
end

describe ContentfulMiddleman::Tools::Backup do
  let(:path) { File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'backup_fixtures')) }
  subject { described_class.new('foo', 'foo_source') }

  before do
    ENV['MM_ROOT'] = path
  end

  describe 'class methods' do
    it '::basepath' do
      expect(described_class.basepath).to eq File.join(path, '.tmp', 'backups')
    end

    describe '::ensure_backup_path!' do
      it 'does nothing if ::basepath exists' do
        expect(FileUtils).not_to receive(:mkdir_p)

        described_class.ensure_backup_path!
      end

      it 'creates basepath directory if it doesnt exist' do
        expect(FileUtils).to receive(:mkdir_p).with(described_class.basepath).and_call_original

        FileUtils.rm_rf(described_class.basepath)

        expect(::File.exist?(described_class.basepath)).to be_falsey

        described_class.ensure_backup_path!

        expect(::File.exist?(described_class.basepath)).to be_truthy
      end
    end
  end

  describe 'instance methods' do
    before do
      # Initialize calls this
      allow(FileUtils).to receive(:mkdir)
      allow(FileUtils).to receive(:mv)
    end

    it '#restore' do
      expect(FileUtils).to receive(:rm_rf).with('foo_source')
      expect(FileUtils).to receive(:mv).with(/foo-/, 'foo_source')

      subject.restore
    end

    it '#destroy' do
      expect(FileUtils).to receive(:rm_rf).with(/foo-/)

      subject.destroy
    end
  end
end

describe DoBackupDouble do
  let(:path) { File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'backup_fixtures')) }

  before do
    ENV['MM_ROOT'] = path

    # Backup::Initialize calls this
    allow(FileUtils).to receive(:mkdir)
    allow(FileUtils).to receive(:mv)
  end

  describe 'ContentfulMiddleman::Tools::Backup::InstanceMethods' do
    describe 'instance methods' do
      describe '#do_with_backup' do
        it 'when invalid path, uses a NullBackup and does nothing' do
          expect(ContentfulMiddleman::Tools::NullBackup).to receive(:new).and_call_original
          expect_any_instance_of(ContentfulMiddleman::Tools::NullBackup).to receive(:destroy)
          subject.do_with_backup('bar', 'baz') { }
        end

        it 'when valid path' do
          expect(ContentfulMiddleman::Tools::Backup).to receive(:new).with('foo', File.join(path, 'baz')).and_call_original
          expect_any_instance_of(ContentfulMiddleman::Tools::Backup).to receive(:destroy)
          subject.do_with_backup('foo', File.join(path, 'baz')) { }
        end

        it 'when error thrown on block, it calls restore' do
          expect(ContentfulMiddleman::Tools::Backup).to receive(:new).with('foo', File.join(path, 'baz')).and_call_original
          expect_any_instance_of(ContentfulMiddleman::Tools::Backup).to receive(:restore)
          expect_any_instance_of(ContentfulMiddleman::Tools::Backup).to receive(:destroy)

          expect { subject.do_with_backup('foo', File.join(path, 'baz')) { raise 'some_error' } }.to raise_error 'some_error'
        end
      end
    end
  end
end
