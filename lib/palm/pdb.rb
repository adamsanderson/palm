require 'enumerator'

# This is a port of Andrew Arensburger's Perl Palm database module
# I have attempted to make the code as ruby friendly as possible, while still working ;)
# Perl code does not good ruby api design make, thus, I'll be moving stuff
# around to make something more natural soon. (Read API changes ahead)
#
# See the README for some more goodies.
#
# It is currently only somewhat tested, so I would love some more feedback
# Adam Sanderson, 2006
# netghost@gmail.com

module Palm
	# Internal structure for storing information about data entries
	DataBlock = 		Struct.new(	:offset, :record_length)
	# Internal structure for recording index information
	RecordIndex = 	Struct.new(	:record_id,:packed_attributes, :offset, :record_length)
	# Internal structure for recording index information
	ResourceIndex =	Struct.new(	:record_id,:record_type, :offset, :record_length)
	
	# PDB handles reading and writing raw Palm PDB records and resources.
	# For most cases, users will probably want to extend this class class, overriding
	# pack_entry and unpack_entry to support their record types.
	#
	# Records are simply stored as an array in +data+, so polish up on your
	# enumerable tricks.  The +created_at+, +modified_at+, and +backed_up_at+
	# attributes are all stored as Times.  Note that +modified_at+ is not
	# automatically updated.
	class PDB
		attr_accessor :name, :attributes, :version
		attr_accessor :created_at, :modified_at, :backed_up_at
		attr_accessor :modnum, :type, :creator
		attr_accessor :unique_id_seed
		attr_accessor :data
		
		HEADER_LENGTH = 32+2+2+(9*4) 	# Size of database header
		RECORD_INDEX_HEADER_LEN = 6 		# Size of record index header
		INDEX_RECORD_LENGTH = 8 			# Length of record index entry
		INDEX_RESOURCE_LENGTH = 10 		# Length of resource index entry
				
		ATTRIBUTE_CODES = {
			"resource"	=>			0x0001,
			"read-only" =>			0x0002,
			"AppInfo dirty" =>	0x0004,
			"backup"	=>				0x0008,
			"OK newer"	=>			0x0010,
			"reset"	 =>					0x0020,
			"launchable"	=>		0x0200,
			"open"	=>					0x8000,
			
			# PalmOS 5.0 attribute names
			"ResDB" =>						0x0001,
			"ReadOnly" =>					0x0002,
			"AppInfoDirty" =>			0x0004,
			"Backup"	=>					0x0008,
			"OKToInstallNewer" =>	0x0010,
			"ResetAfterInstall"=> 0x0020,
			"LaunchableData"	=>	0x0200,
			"Recyclable"	=>			0x0400,
			"Bundle"	=>					0x0800,
			"Open"	=>						0x8000,
		}
		
		# Creates a new PDB.  If +from+ is passed a String, a file will be
		# loaded from that path (see +load_file+).  If a IO object is passed in, 
		# then it will be used to load the palm data (see +load+).
		def initialize(from = nil)
			@attributes = {}
			@data = []
			@appinfo_block = nil
			@sort_block = nil
			@backed_up_at = @created_at = @modified_at = Time.now
			
			case from
			when NilClass
				now = Time.now
				@created_at		= now
				@modified_at	= now
				@version	= 0
				@modnum		= 0
				@type		= "\0\0\0\0"
				@creator	= "\0\0\0\0"
				@unique_id_seed = 0
			when String
				load(open(from))
			when IO
				load(from)
			else
				raise ArgumentError.new("Unknown value to load from #{from.inspect}.  Use a String or IO object.")
			end
		end
		
		# Returns true if the PDB is a set of resources, false if it is a set of records
		def resource?
			@attributes['resource'] || @attributes['ResDB']
		end
		
		# Loads the PDB from a file path
		def load_file(path)
			open path, "r" do |io|
				load io
			end
		end
		
		# Loads the PDB from the given IO source.
		def load(io)
			# Set to binary mode for windows environment
			io.binmode if io.respond_to? :binmode
			
			start_postion = io.pos
			io.seek(0, IO::SEEK_END)
			io_size = io.pos
			io.seek(start_postion)
			
			appinfo_offset, sort_offset = unpack_header(io.read(HEADER_LENGTH))
			
			# parse the record index
			record_index = io.read(RECORD_INDEX_HEADER_LEN)
			next_index, record_count = record_index.unpack("N n")
			
			# load the indexes, gather information about offsets and
			# record lengths
			indexes = nil
			if resource?
				indexes = load_resource_index(io, next_index, record_count)
			else
				indexes = load_record_index(io, next_index, record_count)
			end
			# Add the final offset as a Datablock for the end of the file
			indexes << DataBlock.new(io_size, 0)
			# Fill in the lengths for each of these index entries 
			indexes.each_cons(2){|starts, ends| starts.record_length = ends.offset - starts.offset }
			# Calculate where the data starts (or end of file if empty)
			data_offset = indexes.first.offset
			
			# Pop the last entry back off.  We pushed it on make it easier to calculate the lengths
			# of each entry.
			indexes.pop
			
			# Load optional chunks
			load_appinfo_block(io, appinfo_offset, sort_offset, data_offset) if appinfo_offset > 0
			load_sort_block(io, sort_offset, data_offset) if sort_offset > 0
			
			# Load data
			load_data(io, indexes)
			io.close
		end
		
		protected
		# Custom PDB formats must overide this to support their record format.
		# The default implementation returns
		# RawRecord or RawResource classes depending on the PDB's metadata.
		def unpack_entry(byte_string)
			entry = resource? ? RawResource.new : RawRecord.new
			entry.data = byte_string # Duck typing rules! :)
			entry
		end
		
		# Parses the header, returning the app_info_offset and sort_offset
		def unpack_header(header)			
			@name, bin_attributes, @version, @created_at, @modified_at, @backed_up_at,
			@modnum, appinfo_offset, sort_offset, @type, @creator,
			@unique_id_seed = header.unpack("a32 n n N N N N N N a4 a4 N")
			
			# Clean up some of the input:
			@name.rstrip!	# Get rid of null characters at the end of the name

			ATTRIBUTE_CODES.each do |key,code|
				@attributes[key] = (bin_attributes & code) > 0
			end
			
			@created_at = 	Time.at_palm_seconds @created_at
			@modified_at = 	Time.at_palm_seconds @modified_at
			@backed_up_at = Time.at_palm_seconds @backed_up_at
			[appinfo_offset, sort_offset]
		end
		
		def load_resource_index(io, next_index, record_count)
			(0...record_count).map do |i|
				index = ResourceIndex.new
				resource_index = io.read(INDEX_RESOURCE_LENGTH)
				index.record_type, index.record_id, index.offset = resource_index.unpack "a4 n N"
				index
			end
		end
		
		def load_record_index(io, next_index, record_count)
			last_offset = 0
			(0...record_count).map do |i|
				index = RecordIndex.new
				record_index = io.read(INDEX_RECORD_LENGTH)
				offset, packed_attributes, id_a,id_b,id_c = record_index.unpack "N C C3"
				# The ID is a 3 byte number... of course ;)
				record_id = (id_a << 16) | (id_b << 8) | id_c
				
				index.packed_attributes = packed_attributes
				index.record_id = record_id
				index.offset = offset
				index
			end
		end
		
		def load_appinfo_block(io, appinfo_offset, sort_offset, data_offset)
			if io.pos > appinfo_offset
				raise IOError.new("Bad appinfo_offset (#{appinfo_offset}), while at #{io.pos} of #{io.inspect}.") 
			end
			io.seek(appinfo_offset)
			
			# Read either to the sort offset, or to the data offset
			length = (sort_offset > 0 ? sort_offset : data_offset) - appinfo_offset
			unpack_appinfo_block(io.read(length))
		end
		
		def load_sort_block(io, sort_offset, data_offset)
			if io.pos > sort_offset
				raise IOError.new("Bad sort_offset (#{sort_offset}), while at #{io.pos} of #{io.inspect}.") 
			end
			
			io.seek sort_offset
			# Read to the data offset
			length = data_offset - sort_offset
			unpack_sort_block(io.read(length))
		end
		
		def load_data(io, indexes)
			@data = indexes.map do |index|
				if io.pos > index.offset
					raise IOError.new("Bad index offset (#{index.offset}), while at #{io.pos} of #{io.inspect}.") 
				end
				io.seek index.offset
				
				#Create a record
				byte_string = io.read(index.record_length)
				entry = unpack_entry(byte_string)
				
				# Fill in information from the header
				entry.record_id = index.record_id
				if resource?
					entry.record_type = index.record_type
				else
					entry.packed_attributes = index.packed_attributes
				end
				
				entry
			end
		end
		
		# Custom PDB formats may wish to overide this to support custom appinfo
		# blocks.
		def unpack_appinfo_block(data)
			@appinfo_block = data
		end
		
		# Custom PDB formats may wish to overide this to support custom sort
		# blocks.
		def unpack_sort_block(data)
			@sort_block = data
		end
	
		public
		# Writes to the given path
		def write_file(path)
			open(path, "w") do |io| 
				write io
			end
		end
		
		# Writes PDB to an IO object
		def write(io)		
			io.binmode if io.respond_to? :binmode
			
			# Track the current offset for each section
			offset_position = HEADER_LENGTH + 2 #(2: Index Header length)
			
			index_length = RECORD_INDEX_HEADER_LEN + 
				@data.length * (resource? ? INDEX_RESOURCE_LENGTH : INDEX_RECORD_LENGTH )
			
			offset_position += index_length	# Advance for the index
			
			packed_entries = @data.map{|e| pack_entry(e)}
			
			packed_app_info = pack_app_info_block()
			packed_sort = 		pack_sort_block()
			
			# Calculate AppInfo block offset
			app_info_offset = 0
			if packed_app_info and !packed_app_info.empty?
				app_info_offset = offset_position
				offset_position += packed_app_info.length	# Advance for the app_info_block
			end
			
			# Calculate sort block offset
			sort_offset = 0
			if packed_sort and !packed_sort.empty?
				sort_offset = offset_position
				offset_position += packed_sort.length	# Advance for the sort_block
			end
			
			packed_header = pack_header(app_info_offset, sort_offset)
			
			index_header = [0, @data.length ].pack "N n"

			packed_index = @data.zip(packed_entries).map do |entry, packed|
				index = nil
				if resource?
					index = [entry.record_type, entry.record_id, offset_position].pack "a4 n N"
				else
					index = [
						offset_position, entry.packed_attributes,
						(entry.record_id >> 16) & 0xff,
						(entry.record_id >> 8) & 0xff,
						entry.record_id & 0xff
					].pack "N C C3"
				end
				offset_position += packed.length
				index
			end
			
			# Write to IO stream
			io << packed_header
			io << index_header
			io << packed_index.join
			io << "\0\0" # 2 null byte separator
			io << @app_info_block unless app_info_offset == 0
			io << @sort_block unless sort_offset == 0
			io << packed_entries.join
		end
		
		protected
		def encode_attributes
			encoded = 0
			@attributes.each do |name,flagged|
				encoded |= ATTRIBUTE_CODES[name] if flagged
			end
			
			encoded
		end
		
		def pack_header(app_info_offset, sort_offset)
			attributes = encode_attributes
			
			header_block = [
				@name, attributes, @version, 
				@created_at.to_palm_seconds, @modified_at.to_palm_seconds, @backed_up_at.to_palm_seconds,
				@modnum, app_info_offset, sort_offset,
				@type, @creator,
				@unique_id_seed
			].pack "a32 n n N N N N N N a4 a4 N"
			header_block
		end
		
		# Custom PDB formats must overide this to support their record format.
		def pack_entry(entry)
			entry.data
		end
		
		# Custom PDB formats may wish to overide this to support custom sort
		# blocks.
		def pack_sort_block
			@sort_block
		end
		
		# Custom PDB formats may wish to overide this to support custom appinfo
		# blocks.
		def pack_app_info_block
			@appinfo_block
		end
	end
	
end