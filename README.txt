= Palm
The palm library is a pure ruby library for reading and writing Palm PDB
databases. This library is based off of Andrew Arensburger's pdb.pm.

 Adam Sanderson, 2006
 netghost@gmail.com

= Usage
Here is a sample that reads through and prints some metadata.
   pdb = Palm::PDB.new('palm_db.pdb')
   puts pdb.name
   puts "Creator #{pdb.creator} / Type #{pdb.type}"
   puts "There are #{pdb.data.length} records."

Here is an example of adding and removing records:
   pdb = Palm::PDB.new('palm_db.pdb')
   #Remove the last record
   last_record = pdb.data.pop 
   #Append a new fake record
   pdb.data << Palm::RawRecord.new("This would be binary data")
   pdb.write_file('new_palm_db.pdb')

= Extending
The base Palm::PDB will read and write raw PDB files. Their binary data is
maintained in each record. This is probably not very useful for most cases, but
will allow access to all the common metadata.

To create a more specific implementation, you should override pack_entry and
unpack_entry to handle specific record types. See Palm::WabaDB for an example
implementation supporting Waba format PDBs.

= Plans I am not entirely sold on the current API, a lot of the structure of 
the code is based on Andrew Arensburger's perl code, which doesn't make for 
great ruby code. Where possible I have tried to make the code simpler, but some
perly bits show through. So the API might change a little, I would really 
appreciate some input.

I personally have no need for reading and writing the Palm Todo Lists,
Calendars, Notes, and so forth, however if there is sufficient interest, it
might be fun to add.