module QuickAndDirtyCache
	require 'yaml'
	require 'tmpdir'
	require 'logger'
	require 'fileutils'
	require 'qnd-stores'

	DEFAULT_SETTINGS = {
		primary_cache: QuickAndDirtyCache::Store::InMemoryStore, # Default in-memory store,
		secondary_cache: QuickAndDirtyCache::Store::YAMLDiskStore, # Default disk store
		max_in_memory_objects: 1024, # Maximum number of objects allowed in memory.  -1 indicates unlimited objects allowed
		spools_on_overflow: false, # whether or not to spool to disk once the max_in_memory_objects is reached
		cache_directory: Dir.tmpdir(), # default directory where spooled caches go
		ttl: 3600  # time to live (in seconds) for objects 
	}
	
	@@caches = {}
	LOGGER = Logger.new STDOUT

	def self.cache(cache_name, settings={})
		@@caches[cache_name] = Cache.new(settings) unless @@caches.include? cache_name
		@@caches[cache_name]
	end

	class Cache
		attr_reader :name, :hits, :primary_store, :secondary_store

		def initialize(cache_name, settings={})
			@name = cache_name
			@hits = []
			@settings = DEFAULT_SETTINGS.merge(settings)
			@spools_on_overflow = @settings[:spools_on_overflow]
			LOGGER.info("#{cache_name} intiialized with the following settings: #{@settings}")
			@primary_store = @settings[:primary_cache].new(settings) 
			@lru_linked_list = []
			@secondary_store = @settings[:secondary_cache].new(settings) if spools_on_overflow?		
		end

		def spools_on_overflow?
			@spools_on_overflow
		end

		def size
			@primary_store.open do |store|
				store.length
			end
		end

		# Dumps the entire contents of of the in-memory a cache
		# and optionally the disk cache(if enabled).  This a safe
		# copy and any changes to it will not effect the cache.
		def dump
			temp = @primary_store.dump
			temp.merge!(@secondary_store) if spools_on_overflow?
			temp
		end

		def []=(key, value)
			delete key
			will_cache(key) do
				value
			end
		end

		def [](key)
			object = @primary_store.open do |store|
				if store.include? key
					LOGGER.info "#{key} found in primary cache."
					@lru_linked_list.unshift @lru_linked_list.delete(key)
					object = store[key] 
					object.qnd_metadata[:hits] += 1
					object
				end
			end

			object = @secondary_store.open do |store|
				if store.include? key
					LOGGER.info "'#{key}' found in secondary cache #{store.inspect}."
					@lru_linked_list.unshift key
					object = store.delete key
					if object
						@primary_store[key] = object
						@lru_linked_list.unshift key
						object.qnd_metadata[:hits] += 1
					end
					object
				end
			end if !object && spools_on_overflow?
			if object
				@hits << {key: key, time: Time.now} 
				sweep_memory
			end
			object
		end

		def will_cache(key, &block)
			object = self[key]
	
			if !object
				LOGGER.info "'#{key}' not found in any cache. Creating cache entry with new object."
				object = yield 
				object.class.send(:attr_reader, :qnd_metadata) unless object.respond_to? :qnd_metadata
				object.instance_variable_set("@qnd_metadata", {birthday: Time.now, hits: 0})
				@primary_store[key]=object
				@lru_linked_list.unshift key
				sweep_memory
			end
			object
		end

		def delete(key)	
			@lru_linked_list.delete  key 

			object = @primary_store.open do |store|
				store.delete key
			end

			@secondary_store.open do |store|
				store.delete key
			end if spools_on_overflow? && !object
			object
		end
		
		def prune
			pruner = lambda { |key, value, lru| 
				bday = value.qnd_metadata[:birthday]
				stale = (bday + @settings[:ttl]) < Time.now
				if stale
					lru.delete(key) if lru
					LOGGER.info "Pruning #{key} from the cache
					 as its TTL (#{@settings[:ttl]} seconds) has been exceeded.  
					 Current age #{Time.now - bday}.".gsub(/\s+/, " ").strip
				end
				stale
			}

			@primary_store.open do |store|
				store.delete_if do |key, value|
					pruner.call(key, value, @lru_linked_list)
				end
			end

			@secondary_store.open do |store|
				store.delete_if do |key, value|
					pruner.call(key, value, nil)
				end
			end
		end

		def include?(key)
			@primary_store.include?(key) || (spools_on_overflow? && @secondary_store.include?(key))
		end

		# Attempts reduce size in-memory cache below the 'max_in_memory_objects'
		# setting.
		def sweep_memory
			temp = {}
		
			@primary_store.open do |store|
				while store.length > @settings[:max_in_memory_objects]
					key = @lru_linked_list.pop
					LOGGER.debug "Removing oldest key '#{key}' from in-memory cache as  
					 as the 'max_in_memory_objects' of #{@settings[:max_in_memory_objects]} 
					 has been exceeded.".gsub(/\s+/, " ").strip
					temp[key] = store.delete key
				end
			end unless @settings[:max_in_memory_objects] == -1


			@secondary_store.open do |store|

				temp.each do |key, value|					
					LOGGER.debug "Spooling #{key} => #{value} to secondary cache."	

					store[key] = value

				end
			end if spools_on_overflow? 
		end
	end
end