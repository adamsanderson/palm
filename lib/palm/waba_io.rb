require 'stringio'

module Palm
	# Wildly unoptimized!  50/50 stolen from SuperWaba's datastream and shortcuts with pack ;)
	module WabaIOSupport
		def get_string
			read(get_short)
		end
		
		def get_short
            s = read(2)
            ((s[0] & 0xFF) << 8) | (s[1] & 0xFF)
		end
		
		def get_byte
			readchar
		end
		
		def get_int
			s = read(4)
			((s[0] & 0xFF) << 24) |
			((s[1] & 0xFF) << 16) |
			((s[2] & 0xFF) << 8)  |
			(s[3] & 0xFF)
		end
		
		def get_bool
			read(1)[0] != 0
		end
		
		def write_string(string)
			write_short(string.length)
			write string 
		end
		
		def write_short(short)
	    putc( (short >> 8) & 0xFF )
	    putc( (short >> 0) & 0xFF )
		end
		
		def write_byte(byte)
			putc byte
		end
		
		def write_int(integer)
	    putc( (integer >> 24) & 0xFF )
	    putc( (integer >> 16) & 0xFF )
	    putc( (integer >> 8) & 0xFF )
	    putc( (integer >> 0) & 0xFF )
		end
		
		def write_bool(b)
			putc b ? 1 : 0
		end	
	end
	
	class WabaStringIO < StringIO
		include WabaIOSupport
	end 
	
	class WabaIO < IO
		include WabaIOSupport
	end
	
end