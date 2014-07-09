import sys, getopt, re
from netlib.odict import ODictCaseless
from libmproxy.flow import Response

# def response(context, flow):
# 	if path.search(flow.request.path) is not None:
# 		flow.response.code = 404
# 		flow.response.msg = "Not Found"
#		flow.response.content = "Blacklisted"

def request(context, flow):
	if path.search(flow.request.path) is not None:
			resp = Response(
				flow.request,
				[1,1], 404, "Not Found",
				ODictCaseless([["Content-Type","text/html"],["Server","Apache/2.4.9 (Unix)"]]),
				"Blacklisted",
				None)
			flow.request.reply(resp)

def start(context, argv):
	try:
		opts, args = getopt.getopt(argv[1:], "p:", [])
	except getopt.GetoptError as err:
		print "Error " + err.msg + " " + err.opt
		sys.exit(2)
	for opt, arg in opts:
		global path
		if opt == '-p':
			path = re.compile(arg)