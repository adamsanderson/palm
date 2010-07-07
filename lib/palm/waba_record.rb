module Palm
	WabaField = Struct.new(:name, :type)	
	
	class WabaRecord < Record
		WRITE_TYPES = {
			# 	 															Value  || Default
			:string=>	lambda{|io,v| io.write_string(v||''		)},
			:int=>		lambda{|io,v| io.write_int(		v||0		)},
			:byte=>		lambda{|io,v| io.write_byte(	v||0		)},
			:short=>	lambda{|io,v| io.write_short(	v||0		)},
			:boolean=>lambda{|io,v| io.write_bool( 	v||false)},
		}
	
		READ_TYPES = {
			:string=>	lambda{|io| 	io.get_string },
			:int=>		lambda{|io| 	io.get_int 		},
			:byte=>		lambda{|io| 	io.get_byte		},
			:short=>	lambda{|io| 	io.get_short	},
			:boolean=>lambda{|io| 	io.get_bool 	},
		}
		
		class << self
			def field(name,type)	
		    # Add a new class method to for each trait.
				attr_accessor name
				(@fields ||= []) << WabaField.new(name,type)
			end

			def fields
				@fields.dup
			end
			
			def class_id(value=nil)
				if value
					@class_id = value
				else
					@class_id
				end
			end
		end
		
		def class_id
			self.class.class_id
		end
		
		# Assumes that the class_id has already been read off the stream
		def read(waba_io)
			self.class.fields.each do |f|
				instance_variable_set "@#{f.name}", READ_TYPES[f.type].call(waba_io)
			end
			self
		end
		
		def write(waba_io)
			self.class.fields.each do |f|
				WRITE_TYPES[f.type].call(waba_io, instance_variable_get("@#{f.name}"))
			end
			self
		end
		
	end
end