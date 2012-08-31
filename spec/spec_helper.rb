require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end
require 'qnd-stores'

module LINTStore
	def test_get_set(store)
		store.clear
		store[:foo].should be nil
		store[:foo] = %w{bar baz}
		store[:foo].should eq %w{bar baz}

		if store.instance_of? QuickAndDirtyCache::Store::DiskStoreBase
			puts 'Checking disk for cache file'
			File.exist?(store.cache_file_location).should be true
		end
	end

	def test_include(store)
		store.clear
		store.include?(:foo).should be false
		store[:foo] = 'bar'
		store.include?(:foo).should be true
	end

	def test_clear(store)		
		store.clear
		store[:foo].should be nil
		store[:foo] = 'bar'
		store[:foo].should eq 'bar'
		store.clear
		store.include?(:foo).should be false
		store[:foo].should be nil

		if store.instance_of? QuickAndDirtyCache::Store::DiskStoreBase
			puts 'Checking disk for cache file'
			File.exist?(store.cache_file_location).should be false
		end
	end

	def test_dump(store)
		store.clear
		store[:foo] = 'bar'
		store[:bar] = %w{bar baz}
		dump = store.dump
		dump[:foo].should eq 'bar'
		dump[:bar].should eq %w{bar baz}
	end

	def test_delete(store)
		store.clear
		store[:foo] = 'bar'
		store.delete :foo
		store.include?(:foo).should be false
	end
end

RSpec.configure do |config|
  config.include LINTStore
  config.include LINTStore, :example_group => {
    :describes => lambda {|described| described < QuickAndDirtyCache::Store::Base }
  }
end