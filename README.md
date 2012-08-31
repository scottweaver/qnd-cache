What is QuickAndDirtyCache
==========================
QnD Cache is an in-memory, LRU cache implementation that allows for spooling to a secondary (disk) cache
based on memory settings.

Why QuickAndDirty Cache
=======================
Because all the Ruby cache projects I found where either unmaintained or depended on another cache mechanism
such as memcached or some NoSQL DB.  While these are great options they aren't for everyone, especially if you
work in a large enterprise environment where getting 3rd party software installed on
servers is like pulling teeth. 

Installation
============
Currently QnD Cache is not available through rubygems.org so you will need to install it directly from .gemspec in the Git repo by adding the following line to your Gemfile:

	gem 'qnd-cache', :git => 'https://github.com/scottweaver/qnd-cache'

Then run:

	bundle install

Using QnD Cache
================

First:

	require 'qnd-cache'

There are currently two approaches for using QnD cache.  Directly managing the cache, much like standard Ruby Hash or providing the code you want cached as block to the will_cache method

Directly Accessing the Cache
----------------------------

	qnd = QuickAndDirtyCache::Cache.new("default") # creates a cached named 'default'
	qnd[:foo] = 'foo'
	foo = qnd[:foo]

Using 'will_cache' to Transparently Cache Code
----------------------------------------------

	qnd = QuickAndDirtyCache::Cache.new("default")
	qnd.will_cache('cache key') do
	   # Expensive code that returns a value that will be cached to the key
	   # you provided the will_cache method
	end

Configuring QnD Cache
=====================
You can pass in optional configuration attributes when creating a cache.

	qnd = QuickAndDirtyCache::Cache.new("default", ttl: 30, max_in_memory_objects: 50, spools_on_overflow: true)

The above code creates a cache where each entry has a TTL (Time to Live) of 30 seconds, has a maximum  capacity of 50 objects in memory and will spool out to the secondary cache when the 50 object ceiling has been hit.

Current default settings:

		DEFAULT_SETTINGS = {
			primary_cache: QuickAndDirtyCache::Store::InMemoryStore, # Default in-memory store,
			secondary_cache: QuickAndDirtyCache::Store::YAMLDiskStore, # Default disk store
			max_in_memory_objects: 1024, # Maximum number of objects allowed in memory.  -1 indicates unlimited objects allowed
			spools_on_overflow: false, # whether or not to spool to disk once the max_in_memory_objects is reached
			cache_directory: Dir.tmpdir(), # default directory where spooled caches go
			ttl: 3600  # time to live (in seconds) for objects 
		}

There is a bit more I will get into later involving implementing your own cache stores to back a cache instances and how to use LINTStore in your test cases to make sure your implementation supports all the operations expected of a cache store.