import struct 
import sys

if __name__ == "__main__":

	infile = sys.argv[1]
	outfile = sys.argv[2]

	with open(infile, "rb") as f:
		bindata = f.read();

	data = struct.iter_unpack("I", bindata)
	
	text = [f"{v[0]:x}\n" for v in data]
	text += ["73"]

	with open(outfile, "w") as f:
		f.writelines(text)

