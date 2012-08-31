module QuickAndDirtyCache
	module Store
		class Base
	
				def initialize(settings={})
					@settings = DEFAULT_SETTINGS.merge(settings)
				end
	
				def []=(key, value)
					open do |store|
						store[key] = value
					end
				end
	
				def [](key)
					open do |store|
						store[key]
					end
				end

				def delete(key)
					open do |store|
						store.delete key
					end					
				end
	
				def dump
					open do |store|
						store.clone
					end
				end
	
				def include?(key)
					open do |store|
						store.include? key
					end
				end
	
				def clear
					open do |store|
						store.clear
					end
				end
			end
	
			class InMemoryStore < Base
				def open(&block)
					@memory_cache ||= {}
					yield @memory_cache
				end
			end

			class DiskStoreBase < Base
				
				def initialize(extension='', settings={})
					super settings
				    @extension = extension
				end

				def open(&block)
					QuickAndDirtyCache::LOGGER.warn("!!!*WARNING* you opened a DiskStoreBase while something else has it open.
						This can lead buggy behavior and unpredictable results!!!".gsub(/\s+/, " ").strip) if @open
					begin
						@open = true
						result = nil
						FileUtils.touch(cache_file_location) unless File.exists? cache_file_location
						File.open(cache_file_location, "r+") do |io| 
						#	require 'debugger'; debugger 
							disk_store = load_as_hash(io)
							disk_store ||= {} 
							result = yield disk_store	
							if(disk_store.empty?)
								File.delete cache_file_location
							else
								dump_from_hash(io, disk_store)
							end
						end 
						result
					ensure
						@open = false
					end
				end

				def cache_file_location
					store_id = @settings[:store_id] || 'default'
					@settings[:cache_directory]+"/qnd_#{store_id}.cache#{@extension}"
				end
			end
		
			class YAMLDiskStore < DiskStoreBase
				require 'psych'

				def initialize(settings={})
				    super '.yml', settings
				end
	
				def load_as_hash(io)
					yaml = Psych.load(io)

					yaml
				end

				def dump_from_hash(io, disk_store)
					Monitor.new.synchronize do	
						io.rewind		
						io << Psych.dump(disk_store) 
					end
				end
    		end

    	class MarshallingStore < DiskStoreBase
    		def initialize(settings={})
				super '.bro', settings
			end

			def load_as_hash(io)
		 		io.eof? ? {} : Marshal.load(io)
		 	end

			def dump_from_hash(io, disk_store)
				Monitor.new.synchronize do	
					io.rewind		
					io << Marshal.dump(disk_store) 
				end
			end
    	end
	end
end