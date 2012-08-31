require File.dirname(__FILE__) + "/../spec_helper.rb"
require 'qnd-stores'
require 'qnd-cache'


[QuickAndDirtyCache::Store::InMemoryStore,  
 QuickAndDirtyCache::Store::YAMLDiskStore,
 QuickAndDirtyCache::Store::MarshallingStore].each do |clazz|
	describe clazz do
		before do
		  @store = clazz.new 
		end

		it "should be able to write and retieve to and from its backend" do
			test_get_set @store
		end

		it "should be able check its backend for a specific key" do
			test_include @store
		end
	
		it "should be able to clear its backend" do
			test_clear @store			
		end

		it "should be able to dump its contents to a Hash" do
			test_dump @store
		end

		it "should be able to remove invidual entire by key" do
			test_delete @store
		end
	end
end

describe QuickAndDirtyCache::Store::YAMLDiskStore do
	require 'tmpdir'
	
	it "it create a specific cache file" do
		store = QuickAndDirtyCache::Store::YAMLDiskStore.new
		store.cache_file_location.should eq "#{Dir.tmpdir()}/qnd_default.cache.yml"   
	end
end

