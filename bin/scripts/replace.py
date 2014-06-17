import sys, getopt, re

regexp = ""
replace = ""
path = ""

def response(context, flow):
	# if flow.request.path == path:
	if path.search(flow.request.path) is not None:
		flow.response.content = regexp.sub(replace, flow.response.content, 1)
		flow.response.headers["Content-Length"] =  [str(len(flow.response.content))]


def start(context, argv):
	try:
		opts, args = getopt.getopt(argv[1:], "p:x:r:", [])
	except getopt.GetoptError as err:
		print "Error " + err.msg + " " + err.opt
		sys.exit(2)
	for opt, arg in opts:
		global path
		global regexp
		global replace
		if opt == '-p':
			path = re.compile(arg)
		elif opt == '-x':
			regexp = re.compile(arg)
		elif opt == '-r':
			replace = arg