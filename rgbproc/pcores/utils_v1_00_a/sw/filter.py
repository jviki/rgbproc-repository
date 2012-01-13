#! /usr/bin/python

class EOFException(Exception):
	pass

class ImageLoader:
	"""
	Loads file formated as follows:
	R0 G0 B0
	R1 G1 B1
	...

	where Ri, Gi and Bi represent i'th pixel of RGB color scheme.
	Skips comments starting with '--'
	"""
	def __init__(self, resolution, indata):
		self.indata = indata
		self.width  = resolution[0]
		self.height = resolution[1]

	def reset(self):
		self.indata.rewind()

	def nextPixel(self):
		import re
		line = self.indata.readline()
		if line is None:
			return None

		line = line.strip()
		result = re.match("^([0-9]+) ([0-9]+) ([0-9]+)$", line)
		if result:
			return (int(result.group(1)), int(result.group(2)), int(result.group(3)))

		result = re.match("^--", line)
		if result:
			return self.nextPixel()

		raise Exception("Invalid line in input file: '" + line + "'")

	def nextLine(self):
		line = []
		for i in range(self.width):
			px = self.nextPixel()
			if px is None:
				break

			line.append(px)

		return line
	
class ImageWin:
	"""
	Reads lines from ImageLoader.
	Formats 3x3 windows based on the loaded lines.
	First and last column and first and last row are repeated so that the
	pixel in every window's center is that one loaded by ImageLoader.
	
	Thus printing the center pixel should provide identity:
	  0 1 2 3 4 -> Win -> print win[center] -> 0 1 2 3 4
	Filtering results in sequence of same length.
	"""
	def __init__(self, loader):
		self.loader = loader
		self.reset()

	def reset(self):
		self.loader.reset()
		self.lines = None
		self.px = 0
		self.ln = 0

	def nextLineOrException(self):
		line = self.loader.nextLine()
		if len(line) == 0:
			raise EOFException("End of file")
	
		return line

	def preloadLines(self):
		self.lines = []
		first = self.nextLineOrException()
		self.lines.append(first)
		self.lines.append(first)
		self.lines.append(self.nextLineOrException())

	def loadNextLine(self):
		if self.ln == self.loader.height - 1:
			self.lines[0] = self.lines[1]
			self.lines[1] = self.lines[2]
			self.lines[2] = self.lines[2]
		else:
			self.lines[0] = self.lines[1]
			self.lines[1] = self.lines[2]
			self.lines[2] = self.nextLineOrException()

	def nextPixel(self):
		win = self.nextWin()
		return win[1][1]

	def nextWin(self):
		if self.lines is None:
			self.preloadLines()
		elif self.px == self.loader.width:
			self.ln += 1
			self.loadNextLine()
			self.px = 0

		win = [[-1, -1, -1], [-1, -1, -1], [-1, -1, -1]]

		if self.px == 0:
			win[0][0] = self.lines[0][0]
			win[0][1] = self.lines[0][0]
			win[0][2] = self.lines[0][1]
			win[1][0] = self.lines[1][0]
			win[1][1] = self.lines[1][0]
			win[1][2] = self.lines[1][1]
			win[2][0] = self.lines[2][0]
			win[2][1] = self.lines[2][0]
			win[2][2] = self.lines[2][1]
		elif self.px == self.loader.width - 1:
			win[0][0] = self.lines[0][self.px - 1]
			win[0][1] = self.lines[0][self.px + 0]
			win[0][2] = self.lines[0][self.px + 0]
			win[1][0] = self.lines[1][self.px - 1]
			win[1][1] = self.lines[1][self.px + 0]
			win[1][2] = self.lines[1][self.px + 0]
			win[2][0] = self.lines[2][self.px - 1]
			win[2][1] = self.lines[2][self.px + 0]
			win[2][2] = self.lines[2][self.px + 0]
		else:
			win[0][0] = self.lines[0][self.px - 1]
			win[0][1] = self.lines[0][self.px + 0]
			win[0][2] = self.lines[0][self.px + 1]
			win[1][0] = self.lines[1][self.px - 1]
			win[1][1] = self.lines[1][self.px + 0]
			win[1][2] = self.lines[1][self.px + 1]
			win[2][0] = self.lines[2][self.px - 1]
			win[2][1] = self.lines[2][self.px + 0]
			win[2][2] = self.lines[2][self.px + 1]

		self.px += 1
		return win

class IdentityFilter:
	def __init__(self, win):
		self.win = win

	def nextPixel(self):
		return self.win.nextPixel()

class MedianFilter:
	def __init__(self, win):
		self.win = win

	def medianColor(self, matrix, i):
		l = []
		for row in matrix:
			for col in row:
				l.append(col[i])
		return sorted(l)[5]

	def nextPixel(self):
		matrix = self.win.nextWin()
		r = self.medianColor(matrix, 0)
		g = self.medianColor(matrix, 1)
		b = self.medianColor(matrix, 2)
		return (r, g, b)

class LowPassFilter:
	def __init__(self, win):
		self.win = win

	def lowPass(self, matrix, i):
		return matrix[1][1][i]

	def nextPixel(self):
		matrix = self.win.nextWin()
		r = self.lowPass(matrix, 0)
		g = self.lowPass(matrix, 1)
		b = self.lowPass(matrix, 2)
		return (r, g, b)

class GrayScaleFilter:
	def __init__(self, win):
		self.win = win

	def convert(self, r, g, b):
		cr = (r * 30) / 100
		cg = (g * 59) / 100
		cb = (b * 11) / 100

		return int(cr + cg + cb)

	def nextPixel(self):
		pixel = self.win.nextPixel()
		c = self.convert(pixel[0], pixel[1], pixel[2])
		return (c, c, c)


def testFilter(impl):
	impl.win.reset()
	print("== %s ==" % str(impl.__class__.__name__))
	def px2str(px):
		return "%s %s %s" % px

	try:
		for x in range(640):
			for y in range(480):
				pixel = impl.nextPixel()
				print(px2str(pixel))
	except EOFException as e:
		pass


import sys
def main(source = sys.stdin):
	loader   = ImageLoader((10, 5), source)
	win      = ImageWin(loader)
	identity = IdentityFilter(win)
	median   = MedianFilter(win)
	lowPass  = LowPassFilter(win)
	gray     = GrayScaleFilter(win)

	testFilter(identity)
	testFilter(median)
	testFilter(lowPass)
	testFilter(gray)

class TestInData:
	"""
	Generates testing data:
	0 0 0
	1 1 1
	...
	"""
	def __init__(self, count = 640 * 480):
		self.i   = 0
		self.count = count

	def rewind(self):
		self.i = 0
		
	def readline(self):
		if self.i == self.count:
			return None

		r = self.i
		g = self.i
		b = self.i
		self.i   += 1
		return "%s %s %s" % (r, g ,b)

main(TestInData(10 * 5))

