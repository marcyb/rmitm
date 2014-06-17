import sys, getopt, re

# #########
# p -> escaped regular expression to match against the request path
# f -> path to filename to replace contents with
# #########

path = ""
filename = ""

def response(context, flow):
	if path.search(flow.request.path) is not None:
		flow.response.content = contents()

def contents():
	with open (filename, "r") as myfile:
		return myfile.read().replace('\n', '')

def start(context, argv):
	try:
		opts, args = getopt.getopt(argv[1:], "p:f:", [])
	except getopt.GetoptError as err:
		print "Error " + err.msg + " " + err.opt
		sys.exit(2)
	for opt, arg in opts:
		global path
		global filename
		if opt == '-p':
			path = re.compile(arg)
		elif opt == '-f':
			filename = arg