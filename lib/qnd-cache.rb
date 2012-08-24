module QuickAndDirtyCache
	require 'yaml'

	DEFAULT_SETTINGS = {
		max_in_memory_objects: 100, #Maximum number of objects allowed in memory
		spool_to_disk: false, # whether or not to spool to disk once the max_in_memory_objects is reached
		cach_directory: Dir.tmpdir() # default directory where spooled caches go
		ttl: 3600  # time to live (in seconds) for objects 
	}
	
	@@cache_stores = {}


	class CacheStore
		
		attr_reader :name

		def initialize(store_name, settings={})
			@name = store_name
			@options = DEFAULT_SETTINGS.merge(settings)
			@@ca
		end
	end
	
end