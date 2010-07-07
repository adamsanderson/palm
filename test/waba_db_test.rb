require File.dirname(__FILE__) + '/test_helper.rb'

class TestCollectionPointRecord < Palm::WabaRecord
	class_id 072
	field :corridor, 	:string 
	field :site, 			:string
	field :direction, :byte
	field :lanes, 		:byte
	field :hov_lane, 	:byte
	field :ramp_type, :string
	field :express, 	:boolean
	field :cp_id, 		:int
end

class TC_WabaDBTest < Test::Unit::TestCase
	def setup
		setup_paths
		@pdb = Palm::WabaDB.new(TestCollectionPointRecord)
		@pdb.load(open(@path))
	end
	
	def teardown
		File.delete(@temp_path) if File.exist? @temp_path
	end
	
	def test_records_exist
		assert @pdb.data.length > 0
	end
	
	def test_correct_class
		@pdb.data.each do |record|
			assert_instance_of TestCollectionPointRecord, record
		end
	end
	
	def test_records_look_right
		cp_ids = {}
		@pdb.data.each do |record|
			assert record.corridor.length > 0, 					"Corridor should not be empty"
			assert record.site.length > 0, 							"Site should not be empty"
			assert (1..4).include?(record.direction), 	"Direction should be 1-4"
			assert (0..9).include?(record.lanes), 			"Lanes should be between 0 and 9, found #{record.lanes}"
			assert (0..9).include?(record.hov_lane), 		"Hov Lane should be between 0 and 9, found #{record.hov_lane}"
			assert !cp_ids[record.cp_id], 							"Each cp_id should be unique, #{cp_ids[record.cp_id].inspect} overlaps with #{record.inspect}"
			cp_ids[record.cp_id] = record
		end
	end
	
	
	def test_database_round_tripping
		@pdb.write_file(@temp_path)
		@loaded = Palm::WabaDB.new(TestCollectionPointRecord)
		@loaded.load_file(@temp_path)
		
		# Ensure they're two different objects
		assert(@pdb != @loaded) 
		
		# Test that the loaded data is the same as the original
		@pdb.data.zip(@loaded.data) do |expected, actual|
			assert_equal expected.class.fields, actual.class.fields, "Records should have the same fields"
			expected.class.fields.map{|f| f.name}.each do |name|
				assert_equal expected.send(name), actual.send(name), "Field #{name} did not match"
			end
		end
		
	end
	
	def test_binary_equality
		@pdb.write_file(@temp_path)
		
		# Ensure the files are the same size
		assert_equal File.size(@path), File.size(@temp_path)
		# Ensure the files are identical
		assert_equal IO.read(@path), IO.read(@temp_path)
	end
	
	def test_creating_from_scratch
		@created = Palm::WabaDB.new(TestCollectionPointRecord)
		@created.name = "HovData"
		@created.type = "HovD"
		@created.creator = "Trac"
		@created.created_at = @pdb.created_at
		@created.modified_at = @pdb.modified_at
		@created.backed_up_at = @pdb.backed_up_at
		
		# These are two picky bits.  They don't really need to be equal
		@created.version = 1
		@created.modnum = 420
		
		@pdb.data.each do |r|
			n = TestCollectionPointRecord.new
			# Copy each field
			r.class.fields.map{|f| f.name}.each do |name|
				n.send("#{name}=", r.send(name))
			end
			@created.data << n
		end
		@created.attributes = @pdb.attributes
		@created.write_file(@temp_path)
		
		# Ensure the files are the same size
		assert_equal File.size(@path), File.size(@temp_path)
		
		# First assert the headers are the same
		expected_header = IO.read(@path, Palm::PDB::HEADER_LENGTH).unpack("a32 n n N N N N N N a4 a4 N")
		actual_header = IO.read(@temp_path, Palm::PDB::HEADER_LENGTH).unpack("a32 n n N N N N N N a4 a4 N")
		
		fields = [:name, :bin_attributes, :version, :created_at, :modified_at, :backed_up_at,
		:modnum, :appinfo_offset, :sort_offset, :type, :creator,
		:unique_id_seed]
		
		fields.each_with_index do |field, i|
			assert_equal expected_header[i], actual_header[i], "Header field #{field} should be equal"
		end
		
		# Ensure the files are identical
		expected = IO.read(@path)
		actual = IO.read(@temp_path)
		expected.split('').zip(actual.split('')).each_with_index do |pair, i|
			e,a = pair
			assert_equal e,a, "At #{i}: expected '#{e}', actual'#{a}'"
		end
		
		assert_equal IO.read(@path), IO.read(@temp_path), "Bytes should be identical"
	end
	
	def test_written_records_are_binary_equivalent
		@raw = Palm::PDB.new
		@raw.load_file(@path)
		
		@pdb.data.each_with_index do |r,i|
			io = Palm::WabaStringIO.new(s='', "w")
			r.write(io)
			# The actual db will handle writing the first byte
			assert_equal @raw.data[i].data[1..-1], s, "Data portion should be idential"
		end
	end
	
end