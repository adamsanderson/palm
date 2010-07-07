require File.dirname(__FILE__) + '/test_helper.rb'
require 'enumerator'

class TC_PdbTest < Test::Unit::TestCase
	def setup
		setup_paths
		@pdb = Palm::PDB.new
		@pdb.load_file(@path)
	end

	def teardown
		File.delete(@temp_path) if File.exist? @temp_path
	end

	def test_meta_data
		assert_equal 'Trac'	,			@pdb.creator
		assert_equal 'HovD'	,			@pdb.type
		assert_equal 'HovData'	,	@pdb.name
		assert_equal 1	,					@pdb.version
	end
	
	def test_times_should_be_humane
		assert_instance_of(Time, @pdb.created_at)
		assert_instance_of(Time, @pdb.modified_at)
		assert_instance_of(Time, @pdb.backed_up_at)
	end
	
	def test_writing_data
		@pdb.write_file(@temp_path)
		
		# Ensure the file was written
		assert(File.exist?(@temp_path))
		assert(File.size(@temp_path) > 0)
		
		# Ensure the files are the same size
		assert_equal File.size(@path), File.size(@temp_path)
		
		# Ensure the files are identical
		assert_equal IO.read(@path), IO.read(@temp_path)
	end
	
	def test_round_tripping_records
		@pdb.write_file(@temp_path)
		@loaded = Palm::PDB.new(@temp_path)
		
		# Ensure they are not the same instance
		assert(@pdb != @loaded) 
		
		# Test that the loaded data is the same as the original
		binary_data = @pdb.data.map{|record| record.data}
		loaded_data = @loaded.data.map{|record| record.data}
		
		binary_data.zip(loaded_data) do |expected, loaded|
			assert_equal expected, loaded
		end
		
		# Verify that the metadata is the same
		assert_equal @pdb.creator , @loaded.creator
		assert_equal @pdb.type    , @loaded.type
		assert_equal @pdb.name    , @loaded.name
		assert_equal @pdb.version , @loaded.version
	end
	
	def test_appending_records
		bytes = "TEST BYTES"
		r = Palm::RawRecord.new
		r.data = bytes
		@pdb.data << r
		@pdb.write_file(@temp_path)
		@loaded = Palm::PDB.new(@temp_path)
		assert_equal bytes, @loaded.data.last.data
	end
	
	def test_removing_records
		removed = @pdb.data.shift
		expected = @pdb.data.first
		@pdb.write_file(@temp_path)
		@loaded = Palm::PDB.new(@temp_path)
		assert_equal expected.data, @loaded.data.first.data
		assert !@pdb.data.any?{|r| r.data == removed.data}
	end

end