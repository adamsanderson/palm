module Palm
	# SuperWaba supports Palm PDB files, but handles them a little awkwardly.
	# Each of the file's different record types must be passed in when constructing
	# a new WabaDB so we know what record types are available.
	class WabaDB < Palm::PDB
		# Create a new WabaDB with +record_classes+ as the available types of records.
		# See Palm::WabaRecord for more information.
		def initialize(*record_classes)
			super()
			if record_classes.empty?
				raise ArgumentError.new('At least one WabaRecord class must be provided.')
			end
			@record_index = {}
			record_classes.each{|c| @record_index[c.class_id] = c }
			@last_class = record_classes.first
		end
		
		def unpack_entry(data)
			s = WabaStringIO.new(data)
			class_id = s.get_byte
			c = class_for(class_id)
			c.new.read(s)
		end
		
		def pack_entry(entry)
			data = ""
			s = WabaStringIO.new(data)
			s.write_byte(entry.class_id)
			entry.write(s)
			data
		end
		
		protected
		# Optimized for repeating record classes
		def class_for(i)
			if @last_class.class_id == i
				@last_class
			else
				@last_class = @record_index[i]
			end
		end
		
	end
end