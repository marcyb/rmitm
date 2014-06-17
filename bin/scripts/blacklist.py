import sys, getopt

def response(context, flow):
	if flow.request.path == path: #"/PlaylistService.svc?wsdl":
		flow.response.code = 404
		flow.response.msg = "Not Found"
		flow.response.content = "Oooops!!"

def start(context, argv):
	try:
		opts, args = getopt.getopt(argv[1:], "p:", [])
	except getopt.GetoptError as err:
		print "Error " + err.msg + " " + err.opt
		sys.exit(2)
	for opt, arg in opts:
		global path
		if opt == '-p':
			path = arg