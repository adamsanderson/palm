require 'test/unit'
require File.dirname(__FILE__) + '/../lib/palm'

def setup_paths
	@path = (Dir.pwd =~ /test/) ? "HovData.pdb" : "test/HovData.pdb"
	@temp_path = (Dir.pwd =~ /test/) ? "__tmp.pdb" : "test/__tmp.pdb"
end