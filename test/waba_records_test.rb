require File.dirname(__FILE__) + '/test_helper.rb'

class TestWabaRecord < Palm::WabaRecord
	class_id 072
	field :corridor, 	:string 
	field :site, 			:string
	field :direction, :byte
	def caps_site
		site.upcase
	end
end

class OveridesInitTestWabaRecord < Palm::WabaRecord
	class_id 071
	field :corridor, 	:string 
	field :site, 			:string
	field :direction, :byte
	def initialize
		self.corridor = "I-5"
	end
end

class TC_WabaRecords < Test::Unit::TestCase
	def setup
		@record = TestWabaRecord.new
	end

	def teardown
	end
	
	def test_record_has_expected_fields
		assert_equal(3, TestWabaRecord.fields.length)
		assert_equal [:corridor,:site,:direction], TestWabaRecord.fields.map{|f| f.name}
		assert_equal [:string,:string,:byte], TestWabaRecord.fields.map{|f| f.type}
	end
	
	def test_fields_are_readable_and_writeable
		fill_record(@record)
		assert_record(@record)
	end
	
	# Odd things can happen when metaprogramming, lets make sure variables
	# are stored in the right places
	def test_records_dont_overlap
		a = TestWabaRecord.new; 
		a.site = "A"
		b = TestWabaRecord.new
		b.site = "B"
		assert_equal(a.site, "A")
		assert_equal(b.site, "B")
	end
	
	def test_class_id_is_accesible
		assert_equal(072, @record.class_id)
	end
	
	def test_io_round_tripping
		s = ""
		io = Palm::WabaStringIO.new(s, "w")
		fill_record(@record)
		@record.write(io)
		@load_record = TestWabaRecord.new
		@load_record.read( Palm::WabaStringIO.new(s, "r") )
		assert_record(@load_record)
	end
	
	def test_class_can_have_helper_methods
		fill_record(@record)
		assert_equal "TEST SITE", @record.caps_site
	end
	
	# Regression test, +super+ is now not required in initialize
	# Fixed v0.0.2
	def test_custom_inits
		assert_nothing_raised do 
			@record = OveridesInitTestWabaRecord.new
			assert @record.corridor = "I-5"
			io = Palm::WabaStringIO.new('', "w")
			@record.write(io)
		end
	end
	
	# Nil number values are implicitly written as 0, and strings as empty string
	# Fixed v0.0.3
	def test_writing_null_data
		assert_nothing_raised do 
			assert_equal nil, @record.direction
			io = Palm::WabaStringIO.new(s = '', "w")
			@record.write(io)
			assert s.length > 0	# ha! I had forgotten to write it out :)
			@load_record = TestWabaRecord.new
			@load_record.read(Palm::WabaStringIO.new(s, "r") )
			assert_equal 0, @load_record.direction
		end
	end
	
	def fill_record(record)
		record.corridor		= "I-5"
		record.direction	= 4
		record.site 			= "Test Site"
	end
	
	def assert_record(record)
		assert_equal("I-5", record.corridor)
		assert_equal(4, record.direction)
		assert_equal("Test Site", record.site)
	end
	
end