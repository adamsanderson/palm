module Palm
	# Stores the contents of the record in the data attribute as a byte string.  
	# This is suitable for any record where the actual content of the record is irrelevant.
	class RawRecord < Record
		attr_accessor	:data
		def initialize(bytes=nil)
			super()
			@data = bytes
		end
	end
	
	# Stores the contents of the resource in the data attribute as a byte string.  
	# This is suitable for any resource where the actual content of the resource is irrelevant.
	class RawResource < Resource
		attr_accessor	:data
		def initialize(bytes=nil)
			super()
			@data = bytes
		end
	end
end