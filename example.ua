-- default ostream
stl.cout (stl.showpos) (stl.showbase) (stl.uppercase) (stl.hex) (255) (" ") (stl.oct) (255) (" ") (stl.dec) (255) (stl.endl) -- "0xFF 0377 +255"
stl.cout (stl.setprecision(5)) (0.00001) (" ") (stl.scientific) (0.00001) (" ") (stl.defaultfloat) (0.00001) (stl.endl) -- "0.00001 1.00000e-05 1e-05"
stl.cout (stl.setw(10)) (stl.left) ("left") (stl.right) ("right") (stl.endl) -- "left           right"

-- file ostream
local file = io.open("test.txt", "w")
local fs = stl.ostream(file)
fs ("Hello world") -- write to file "Hello world"
file:close()
