# Class extensions for making palm data easier to work with
class Time
	EPOC_1904 = 2082844800 				# Difference between Palm's epoch
	
	def to_palm_seconds
		to_i + EPOC_1904
	end
	
	def self.at_palm_seconds(seconds)
		at(seconds - EPOC_1904)
	end
end