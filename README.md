RMITM
=====

__RMITM__ provides a ruby interface to mitmdump - the command line version of [mitmproxy][0].

## Installation

### Prerequisites
(Obviously) [mitmproxy][1] must be installed.

__Note:__ Some corporate firewalls may block access to [http://mitmproxy.org][0]. In this case, the source of the site is available via [github][2] - specifically the [installation page][3].

### Compatibility
__RMITM__ is developed and used on OSX. Although there is no obvious reason why __RMITM__ wouldn't work on Linux, this is untested. 

For Windows, there *are* specific reasons why some features of __RMITM__ would not work as is. Fixing these would be fairly straightforward, should you need to, but up to now running on Windows hasn't been a requirement. 

### Install from source

__RMITM__ is not currently published on any public gem repositories. The gem can however be built and installed locally using the gemspec file.

1. `gem build rmitm.gemspec`
2. `gem install rmitm-0.0.1.gem`

## Motivation
__RMITM__ came about from the need to automate a pack of manual functional web tests in Ruby. The manual tests used a proxy application to modify specific server responses, but the proxy application only had a limited API that enabled turning functionality on or off, not configure responses on a per test basis.

A number of alternative proxies were investigated and [mitmproxy][4] was identified as the closest match to the requirements, except that it was implemented in Python. The decision was therefore made to implement a new HTTP proxy in Ruby. 

This worked fine until the requirements changed and some of the requests needed to be made over HTTPS. It was decided that adding "[man-in-the-middle][5]" functionality to the Ruby proxy would be more complex than creating an integration layer for [mitmdump][6] in Ruby. Hence __RMITM__ was created.

## License

    Copyright (C) 2014  Marc Bleeze (marcbleeze<at>gmail<dot>com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.

## Usage

### Mitmdump

##### Initialization
A new instance of `Mitmdump` can be initialized with an optional path array specifying where custom mitmdump scripts are located:

```ruby
m = Mitmdump.new(['.', './scripts', '~/python/mitmdump/scripts'])
```

##### Starting proxy
Once initialized the proxy can be started by calling `#start`	with an optional hash of arguments. The arguments are passed on directly to the mitmdump command line - for details of valid options see the [mitmdump documentation][6] and/or run `mitmdump --help` from a terminal.

```ruby
Mitmdump.new.start({'-p' => '8888', '-w' => 'my.dump'})
```

By default the proxy starts on port 8080 and outputs traffic flows to *./dumps/mitm.dump* (any required directories will be created, subject to permissions).

Since `Mitmdump` is intended for use with test automation the proxy will __always start in quiet mode__.

#### Scripting
Altering specific requests or responses in your application traffic flow is achieved using [mitmproxy's scripting API][7]. 

##### __RMITM__ bundled scripts
__RMITM__ includes Python scripts for some common functionality.

Currently these are:

* __Blacklist__ - returns a 404 response if the request path matches a regular expression
* __Map local__ - the response content for any request with a path matching a regular expression will contain the contents of the file provided
* __Replace__ - for any request with a path matching a regular expression, any text in the response content matching a second regular expression will be replaced with the provided string
* __Strip Encoding__ - removes the *Accept-Encoding* header from the request headers so that traffic is not compressed

##### Script API

For each bundled script there is an API method to add the script to the proxy session.

```ruby
m.blacklist('\/collect\?')

m.map_local('\/', 'local_homepage.html')

m.replace(
	'\/application_config\.js',
	'name=\"someParam\" value=\"\d+\"',
	"name=\\\"someParam\\\" value=\\\"#{new_value}\\\""
)

m.strip_encoding
```

Note that, since strings will be passed to mitmdump via the command line, special attention needs to be paid to escaping quotes.

##### Custom scripts

Your own Python scripts can be added to the proxy start call:

```ruby
m = Mitmdump.new
m.start({'-s' => 'add_header.py'})
```

Or, before the proxy is started, can be added using `#add_script_to_startup`:

```ruby
m.add_script_to_startup('add_header.py')
m.start
```

Non-anonymous script arguments can be passed in a hash: 

```ruby
m.add_script_to_startup('myscript.py', {'-h' => host, '-u' => user})
```

Attempting to add a script once mitmdump has already started will do nothing.

##### Script naming and selection
When adding a script only the filename (e.g. _myscript.py_) needs to be provided. A corresponding file will be searched for in the bundled scripts and then each of the [script locations specified in the path array][8] in turn. The first script with a matching filename will be used.

##### Stopping proxy
```ruby
m.stop
```

__Note:__ calling `#stop` on any instance of `Mitmdump` will actually stop __all__ running mitmdump processes.

##### Retrieving proxy details
The following can be used to retrieve information about a running instance of `Mitmdump`:

* `#dumpfile` - returns the location of the mitmdump flow dump
* `#port` - returns the port mitmdump is listening on
* `#script_paths` - returns script path array passed in initialization

Before calling `#start`, details of the scripts that will be passed to mitmdump on the command line can be retrieved using `#scripts`. Once mitmdump is running `#scripts` will return an empty array.

### Reading from an mitmdump output file

#### MitmdumpReader
`MitmdumpReader` enables reading from an mitmdump output file to JavaScript Object Notation (JSON).

```ruby
reader = MitmdumpReader.new(m.dumpfile)
reader.get_flows_from_file		# returns an array of all flows in file in JSON format
reader.get_requests_from_file		# returns an array of all requests in file in JSON format
reader.get_responses_from_file		# returns an array of all responses in file in JSON format
```

If you need to run validations or queries on the contents of the dumpfile it is generally more practical to use `MitmFlowArray` instead of `MitmdumpReader`. `MitmdumpReader` is just a Ruby integration layer for a Python program that parses the mitmdump output file format into JSON.

### MitmFlowArray
`MitmFlowArray` provides utility methods for filtering the recorded flows by one or more conditions and returning specific values from the JSON. [JSONPath][9] is used to achieve this.

```ruby
f = MitmFlowArray.from_file(m.dumpfile)
hosts = f.values_by_jpath('$..request.host')
response_codes = f.values_by_jpath('$..response.code')

conditions = [
	['$..request.host', /stackoverflow\.com/],
	['$..request.method', /POST/i]
]
so_post_request_paths = f.filter(conditions).values_by_jpath('$..request.path')
```

Given the structure of the JSON produced by `MitmdumpReader` it is unexpected that a given JSONPath expression will yield more than one value per 'flow'. Consequently, by default, `#values_by_jpath` returns an array of the first values found:

```ruby
response_codes = f.values_by_jpath('$..response.code')
# ==> [200, 200]
```

An array of arrays of all values per flow that match the JSONPath expression can also be returned:

```ruby
response_codes = f.values_by_jpath('$..response.code', false)
# ==> [[200], [200]]
```

[0]: http://mitmproxy.org
[1]: http://mitmproxy.org/doc/install.html
[2]: https://github.com/mitmproxy/mitmproxy
[3]: https://github.com/mitmproxy/mitmproxy/blob/master/doc-src/install.html
[4]: http://mitmproxy.org/doc/mitmproxy.html
[5]: http://en.wikipedia.org/wiki/Man-in-the-middle_attack
[6]: http://mitmproxy.org/doc/mitmdump.html
[7]: http://mitmproxy.org/doc/scripting/inlinescripts.html
[8]: #initialization
[9]: http://goessner.net/articles/JsonPath/