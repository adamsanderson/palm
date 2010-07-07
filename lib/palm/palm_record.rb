module Palm
	# Base class for all Palm::PDB Records.  This stores the basic metadata for each
	# record.  Subclasses should extend this provide a useful interface for accessing
	# specific record types.
	class Record
		RECORD_ATTRIBUTE_CODES = {
			:expunged 	=>    0x80,
			:dirty 	 		=>    0x40,
			:deleted  	=>    0x20,
			:private   	=>    0x10
		}
		
		attr_accessor :expunged, :dirty, :deleted, :private, :archive
		attr_accessor :record_id, :category
		
		def initialize
			@category = 	0
			@record_id = 	0
			@dirty = 			true
		end
		
		def packed_attributes
			encoded = 0
			if @expunged or @deleted
				encoded |= 0x08 if @archive
			else
				encoded = @category & 0x0f
			end
			
			RECORD_ATTRIBUTE_CODES.each do |name,code|
				encoded |= code if send(name)
			end
			
			encoded
		end
		
		def packed_attributes=(value)
			RECORD_ATTRIBUTE_CODES.each do |key,code|
				self.send("#{key}=", (value & code) > 0)
			end
			if (value & 0xa0) == 0
				@category = (value & 0x0f)
			else
				@archive = (value & 0x08) > 0
			end
		end

	end
	
	# Base class for all Palm::PDB Resources.  This stores the basic metadata for each
	# record.  Subclasses should extend this provide a useful interface for accessing
	# specific record types.
	class Resource
		attr_accessor :record_type, :record_id
		def intialize
			@record_type = "\0\0\0\0"
			@record_id = 0
		end
		
	end
	
end