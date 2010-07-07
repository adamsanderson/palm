require File.dirname(__FILE__) + '/test_helper.rb'

class TC_WabaIOTest < Test::Unit::TestCase
	def setup
		setup_paths
		@pdb = Palm::PDB.new
		@pdb.load_file(@path)
	end

	def teardown
		File.delete(@temp_path) if File.exist? @temp_path
	end
	
	def test_that_data_looks_right
		records = @pdb.data
		io = Palm::WabaStringIO.new(records.first.data)
		assert_equal 072           	,io.get_byte
		assert_equal 'Downtown I-5'	,io.get_string
		assert_equal 'Albro Pl'    	,io.get_string 	
		assert_equal 1           		,io.get_byte	  
		assert_equal 5           		,io.get_byte	  
		assert_equal 5           		,io.get_byte	  
		assert_equal 'none'      		,io.get_string 	
		assert_equal false       		,io.get_bool	  
		assert_equal 21          		,io.get_int	
	end
	
	def test_reading_shorts
		records = @pdb.data
		io = Palm::WabaStringIO.new(records.first.data)
		assert_equal 072           	,io.get_byte
		# next is a string which begins with a short
		# indicating the string length
		assert_equal 'Downtown I-5'.length	,io.get_short
	end
	
	def test_round_tripping
		io = Palm::WabaStringIO.new
		# Write my data out
		io.write_string "Hello"
		io.write_int 42
		io.write_short 7
		io.write_bool true
		io.write_bool nil
		
		# Assert my position is: 
		# 2(short) + 5(string) + 4(int) + 2(short) +1(bool) +1(bool) = 13
		assert_equal 15, io.pos
		
		# Reset
		io.seek 0
		
		# Read back the results
		assert_equal "Hello", io.get_string
		assert_equal 42, io.get_int
		assert_equal 7, io.get_short
		assert_equal true, io.get_bool
		assert_equal false, io.get_bool
	end
	
end