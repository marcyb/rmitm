def request(context, flow):
	del flow.request.headers['Accept-Encoding']