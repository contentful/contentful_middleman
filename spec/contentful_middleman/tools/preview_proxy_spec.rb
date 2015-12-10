require 'spec_helper'

describe ContentfulMiddleman::Tools::PreviewProxy do
  subject do
    preview_proxy = nil
    vcr('tools/preview_helper') {
      preview_proxy = described_class.instance(space: 'cfexampleapi', access_token: 'b4c0n73n7fu1')
    }
    preview_proxy
  end

  before(:each) do
    subject.clear_cache
  end

  describe 'class methods' do
    describe '::instance' do
    end

    it '::days' do
      expect(DateTime.new(2015, 1, 1, 0, 0, 0) + described_class.days(1)).to eq(DateTime.new(2015, 1, 2, 0, 0, 0))
    end

    it '::hours' do
      expect(DateTime.new(2015, 1, 1, 0, 0, 0) + described_class.hours(1)).to eq(DateTime.new(2015, 1, 1, 1, 0, 0))
    end

    it '::minutes' do
      expect(DateTime.new(2015, 1, 1, 0, 0, 0) + described_class.minutes(1)).to eq(DateTime.new(2015, 1, 1, 0, 1, 0))
    end

    it '::seconds' do
      expect(DateTime.new(2015, 1, 1, 0, 0, 0) + described_class.seconds(1)).to eq(DateTime.new(2015, 1, 1, 0, 0, 1))
    end
  end

  describe 'cache expiration can be configured' do
    before do
      described_class.class_variable_set(:@@instances, [])
    end

    after do
      described_class.class_variable_set(:@@instances, [])
    end

    it 'by tries' do
      preview = nil
      vcr('tools/preview_helper') {
        preview = described_class.instance(space: 'cfexampleapi', access_token: 'b4c0n73n7fu1', tries: 5)
      }

      vcr('tools/preview_helper/entries') {
        preview.entries
      }

      preview.entries
      preview.entries
      preview.entries
      preview.entries
      preview.entries

      expect { preview.entries }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
    end

    describe 'by expire time' do
      it 'will always refetch when expiry is before now' do
        preview = nil
        vcr('tools/preview_helper') {
          # Expired 5 minutes ago (will always refetch)
          preview = described_class.instance(space: 'cfexampleapi', access_token: 'b4c0n73n7fu1', expires_in: described_class.minutes(-5))
        }

        vcr('tools/preview_helper/entries') {
          preview.entries
        }

        expect { preview.entries }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end

      it 'will never refetch until expired' do
        preview = nil
        vcr('tools/preview_helper') {
          # We put a ridiculously high number of tries to test expiration date
          preview = described_class.instance(space: 'cfexampleapi', access_token: 'b4c0n73n7fu1', tries: 10000, expires_in: described_class.days(2))
        }

        vcr('tools/preview_helper/entries') {
          preview.entries
        }

        preview.entries
        preview.entries
        preview.entries
        preview.entries

        # ... this could go for 2 days straight without refetching ...

        preview.entries
        preview.entries
        preview.entries
        preview.entries

        # We force the cache to expire
        preview.clear_cache

        expect { preview.entries }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end
    end
  end

  describe 'instance methods' do
    describe '#entries' do
      it 'on first run fetches entries from preview api' do
        vcr('tools/preview_helper/entries') {
          subject.entries
        }
      end

      it 'on subsequent runs it doesnt' do
        vcr('tools/preview_helper/entries') {
          subject.entries
        }

        subject.entries
      end

      it 'but runs on different queries' do
        vcr('tools/preview_helper/entries') {
          subject.entries
        }

        subject.entries

        vcr('tools/preview_helper/entries_2') {
          subject.entries(content_type: 'cat')
        }
      end

      it 'caches taking into account the query' do
        vcr('tools/preview_helper/entries') {
          subject.entries
        }

        subject.entries

        vcr('tools/preview_helper/entries_2') {
          subject.entries(content_type: 'cat')
        }

        subject.entries(content_type: 'cat')
      end

      it 'forces a cache refresh after 3 consecutive queries' do
        vcr('tools/preview_helper/entries') {
          subject.entries
        }

        subject.entries
        subject.entries
        subject.entries

        expect { subject.entries }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end

      it 'should re-fetch after expire time' do
        vcr('tools/preview_helper/entries') {
          subject.entries
        }

        subject.instance_variable_get(:@cached_entry_collection)[Marshal.dump({})][:expires] = DateTime.now - 1

        expect { subject.entries }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end
    end

    describe '#assets' do
      it 'on first run fetches assets from preview api' do
        vcr('tools/preview_helper/assets') {
          subject.assets
        }
      end

      it 'on subsequent runs it doesnt' do
        vcr('tools/preview_helper/assets') {
          subject.assets
        }

        subject.assets
      end

      it 'but runs on different queries' do
        vcr('tools/preview_helper/assets') {
          subject.assets
        }

        subject.assets

        vcr('tools/preview_helper/assets_2') {
          subject.assets(order: 'sys.createdAt')
        }
      end

      it 'caches taking into account the query' do
        vcr('tools/preview_helper/assets') {
          subject.assets
        }

        subject.assets

        vcr('tools/preview_helper/assets_2') {
          subject.assets(order: 'sys.createdAt')
        }

        subject.assets(order: 'sys.createdAt')
      end

      it 'forces a cache refresh after 3 consecutive queries' do
        vcr('tools/preview_helper/assets') {
          subject.assets
        }

        subject.assets
        subject.assets
        subject.assets

        expect { subject.assets }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end

      it 'should re-fetch after expire time' do
        vcr('tools/preview_helper/assets') {
          subject.assets
        }

        subject.instance_variable_get(:@cached_asset_collection)[Marshal.dump({})][:expires] = DateTime.now - 1

        expect { subject.assets }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end
    end

    describe '#entry' do
      it 'on first run fetches entry from preview api' do
        vcr('tools/preview_helper/entry') {
          subject.entry('garfield')
        }
      end

      it 'on subsequent runs it doesnt' do
        vcr('tools/preview_helper/entry') {
          subject.entry('garfield')
        }

        subject.entry('garfield')
      end

      it 'but runs on different queries' do
        vcr('tools/preview_helper/entry') {
          subject.entry('garfield')
        }

        subject.entry('garfield')

        vcr('tools/preview_helper/entry_2') {
          subject.entry('happycat')
        }
      end

      it 'caches taking into account the query' do
        vcr('tools/preview_helper/entry') {
          subject.entry('garfield')
        }

        subject.entry('garfield')

        vcr('tools/preview_helper/entry_2') {
          subject.entry('happycat')
        }

        subject.entry('happycat')
      end

      it 'forces a cache refresh after 3 consecutive queries' do
        vcr('tools/preview_helper/entry') {
          subject.entry('garfield')
        }

        subject.entry('garfield')
        subject.entry('garfield')
        subject.entry('garfield')

        expect { subject.entry('garfield') }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end

      it 'should re-fetch after expire time' do
        vcr('tools/preview_helper/entry') {
          subject.entry('garfield')
        }

        subject.instance_variable_get(:@cached_entries)[Marshal.dump({cache_id: 'garfield'})][:expires] = DateTime.now - 1

        expect { subject.entry('garfield') }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end
    end

    describe '#asset' do
      it 'on first run fetches asset from preview api' do
        vcr('tools/preview_helper/asset') {
          subject.asset('nyancat')
        }
      end

      it 'on subsequent runs it doesnt' do
        vcr('tools/preview_helper/asset') {
          subject.asset('nyancat')
        }

        subject.asset('nyancat')
      end

      it 'but runs on different queries' do
        vcr('tools/preview_helper/asset') {
          subject.asset('nyancat')
        }

        subject.asset('nyancat')

        vcr('tools/preview_helper/asset_2') {
          subject.asset('happycat')
        }
      end

      it 'caches taking into account the query' do
        vcr('tools/preview_helper/asset') {
          subject.asset('nyancat')
        }

        subject.asset('nyancat')

        vcr('tools/preview_helper/asset_2') {
          subject.asset('happycat')
        }

        subject.asset('happycat')
      end

      it 'forces a cache refresh after 3 consecutive queries' do
        vcr('tools/preview_helper/asset') {
          subject.asset('nyancat')
        }

        subject.asset('nyancat')
        subject.asset('nyancat')
        subject.asset('nyancat')

        expect { subject.asset('nyancat') }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end

      it 'should re-fetch after expire time' do
        vcr('tools/preview_helper/asset') {
          subject.asset('nyancat')
        }

        subject.instance_variable_get(:@cached_assets)[Marshal.dump({cache_id: 'nyancat'})][:expires] = DateTime.now - 1

        expect { subject.asset('nyancat') }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
      end
    end
  end
end
