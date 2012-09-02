require File.dirname(__FILE__) + "/../spec_helper.rb"
require 'qnd-cache'

describe QuickAndDirtyCache::Cache do
	it "Should store items returned from the cached block" do
		qnd = QuickAndDirtyCache::Cache.new "default"

		call_count = 0

		qnd.size.should eq 0
		qnd.hits.length.should eq 0
		result = qnd.will_cache('foo') do 
			call_count += 1
			'bar'
		end
		qnd.hits.length.should eq 0
		qnd.size.should eq 1
		call_count.should eq 1
		result.should eq 'bar'

		result = qnd.will_cache('foo') do 
			call_count += 1
			'bar'
		end
		result.should eq 'bar'
		qnd.hits.length.should eq 1
		call_count.should eq 1
		qnd.size.should eq 1
	end

	it "should add metadata to cached objects" do
		qnd = QuickAndDirtyCache::Cache.new "default"

		test ="foobar"
		result = qnd.will_cache('foo') do 
			test
		end
		
		test.respond_to?(:qnd_metadata).should be true
	end

	it "should record number of hits per cached object" do
		qnd = QuickAndDirtyCache::Cache.new "default"

		test ="foobar"
		qnd.will_cache('foo') do 
			test
		end

		test.qnd_metadata[:hits].should eq 0
		qnd.will_cache('foo') do 
			test
		end

		test.qnd_metadata[:hits].should eq 1
		qnd.will_cache('foo') do 
			test
		end

		test.qnd_metadata[:hits].should eq 2
	end

	it "should not exceed the max_in_memory_objects setting" do
		qnd = QuickAndDirtyCache::Cache.new("default", max_in_memory_objects: 1)

		qnd.size.should eq 0
		qnd.will_cache(:foo)  do
			"foo"
		end

		qnd.dump.include?(:foo).should be true
		qnd.size.should eq 1
		qnd.will_cache(:bar)  do
			"bar"
		end

		qnd.dump.include?(:bar).should be true
		qnd.dump.include?(:foo).should be false
		qnd.size.should eq 1
	end

	it "should write to the secondary cache when the in-memory max size is reached" do
		qnd = QuickAndDirtyCache::Cache.new("default", max_in_memory_objects: 1, spools_on_overflow: true)
		qnd[:foo] = 'foo'
		qnd[:bar] = 'bar'
		qnd.primary_store.include?(:bar).should be true
		qnd.primary_store.include?(:foo).should be false

		qnd.secondary_store.include?(:bar).should be false
		qnd.secondary_store.include?(:foo).should be true

	end

	it "should move requested objects from the secondary cache to the primary cache when fetching from secondary cache", focus: true do
		qnd = QuickAndDirtyCache::Cache.new("default", max_in_memory_objects: 1, spools_on_overflow: true)

		qnd[:foo] = 'foo'

		qnd[:bar] = 'bar'
		qnd.primary_store.include?(:bar).should be true
		qnd.primary_store.include?(:foo).should be false

		qnd.secondary_store.include?(:bar).should be false
		qnd.secondary_store.include?(:foo).should be true

		PP.pp qnd.secondary_store.dump

		qnd[:foo]
		qnd[:foo].should eq 'foo'

		PP.pp qnd.secondary_store.dump

		qnd.primary_store.include?(:bar).should be false
		qnd.primary_store.include?(:foo).should be true

		qnd.secondary_store.include?(:bar).should be true
		qnd.secondary_store.include?(:foo).should be false
		
	end

	it "should prune expired objects from the cache" do
		# Create a teeny weeny cache so that we can see pruning in action on both primary and secondary caches
		qnd = QuickAndDirtyCache::Cache.new("default", max_in_memory_objects: 1, ttl: 1, 
			spools_on_overflow: true)
		qnd[:foo] = 'foo'
		qnd[:bar] = 'bar'
		sleep 1.5
		qnd.prune
		qnd.size.should eq 0
		qnd[:foo].should be nil
		qnd[:bar].should be nil
	end

	it "should know whether or not a key exists in either the primary or secondary cache" do
		qnd = QuickAndDirtyCache::Cache.new("default", max_in_memory_objects: 1, spools_on_overflow: true)

		qnd[:foo] = 'foo'
		qnd[:bar] = 'bar'
		qnd.primary_store.include?(:bar).should be true
		qnd.secondary_store.include?(:foo).should be true
		qnd.include?(:foo).should be true
		qnd.include?(:bar).should be true
	end

end

describe QuickAndDirtyCache do 
	it "should keep a list of register caches and create new ones if they don't exist" do
		cache = QuickAndDirtyCache.cache :default
		cache.should_not be nil
		cache2 = QuickAndDirtyCache.cache :default
		cache2.should eq cache
		cache3 = QuickAndDirtyCache.cache :new_cache
		cache3.should_not eq cache
	end
	
end