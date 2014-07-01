RMITM
=====

__RMITM__ provides a ruby interface to mitmdump - the command line version of [mitmproxy][0].

## Installation

```ruby
gem install rmitm
```

### Prerequisites
(Obviously) [mitmproxy][1] must be installed.

__Note:__ Some corporate firewalls may block access to [http://mitmproxy.org][0]. In this case, the source of the site is available via [github][2] - specifically the [installation page][3].

### Compatibility
__RMITM__ is developed and used on OSX. Although there is no obvious reason why __RMITM__ wouldn't work on Linux, this is untested. 

For Windows, there _are_ specific reasons why some features of __RMITM__ would not work as is. Fixing these would be fairly straightforward, should you need to, but up to now running on Windows hasn't been a requirement. 

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

# Usage

## Mitmdump

### Defining proxies
`Mitmdump` configurations are defined using a DSL:

```ruby
mitmdump :p1 do
  port 8888
  output 'my.dump'
end
=> #<Mitmdump:0x007fc321a479f0 @name=:p1, @port=8888, @output="my.dump", @scripts=[], @params={}>
```

By default the proxy starts on port 8080 and outputs traffic flows to _./dumps/mitm.dump_ (any required directories will be created, subject to permissions).

```ruby
mitmdump :default do
end
=> #<Mitmdump:0x007fc321a71610 @name=:default, @port=8080, @output="dumps/mitm.dump", @scripts=[], @params={}>
```

Since `Mitmdump` is intended for use with test automation the proxy will __always start in quiet mode__.

#### Loading proxies from file
At runtime the named configurations can be loaded from file(s) using a [glob pattern][10]. For example, if the configuration above is defined in _./features/support/mitm/config.mitm_:

```ruby
load_proxies('./features/support/mitm/*.mitm')
```
Loading the proxies creates a hash of proxy configs that can be retrieved by name using `#proxy`:

```ruby
{:p1=>
  #<Mitmdump:0x007fc321a479f0
   @name=:p1,
   @output="my.dump",
   @params={},
   @port=8888,
   @scripts=[]>,
 :default=>
  #<Mitmdump:0x007fc321a71610
   @name=:default,
   @output="dumps/mitm.dump",
   @params={},
   @port=8080,
   @scripts=[]>}

proxy('p1')
=> #<Mitmdump:0x007fc321a479f0 @name=:p1, @port=8888, @output="my.dump", @scripts=[], @params={}>
```

### Starting proxy
```ruby
proxy('p1').start
```

### Stopping proxy
```ruby
proxy('p1').stop
```

### Scripting
Altering specific requests or responses in your application traffic flow is achieved using [mitmproxy's scripting API][7]. 

#### __RMITM__ bundled scripts
__RMITM__ includes Python scripts for some common functionality.

Currently these are:

* __Blacklist__ - returns a 404 response if the request path matches a regular expression
* __Map local__ - the response content for any request with a path matching a regular expression will contain the contents of the file provided
* __Replace__ - for any request with a path matching a regular expression, any text in the response content matching a second regular expression will be replaced with the provided string
* __Strip Encoding__ - removes the *Accept-Encoding* header from the request headers so that traffic is not compressed

### DSL
#### Already demonstrated above
`port` - specifies the port for the proxy to listen on, defaults to 8080 if not provided

`output` - specifies the file for mitmdump to write traffic flows to, defaults to _dumps/mitm.dump_

#### Bundled scripts
```ruby
mitmdump :example do
  blacklist '\/collect\?'

  map_local '\/',
    :with => 'local_homepage.html'

  replace '\/application_config\.js',
  	:swap => 'name=\"timeout\" value=\"\d+\"',
  	:with => "name=\\\"timeout\\\" value=\\\"10\\\""

  strip_encoding
end
```

Note that, since strings will be passed to mitmdump via the command line, special attention needs to be paid to escaping quotes.

#### Custom scripts

Your own custom Python scripts can also be added:

```ruby
mitmdump :custom do
  script '/custom/add_header.py'
end
```

Non-anonymous script arguments can be passed in a hash: 

```ruby
mitmdump :custom_with_args do
  script 'lib/python/myscript.py', '-h' => 'host.com', '-u' => 'user1'
end
```

#### Parameterisation
Parameters, denoted by `%`, can be included in script argument strings, however for the replacement to succeed at runtime, they must also be declared using `param`:

```ruby
mitmdump :parameter_example do
  param 'new_value'
  replace '\/application_config\.js',
    :swap => 'name=\"timeout\" value=\"\d+\"',
    :with => "name=\\\"timeout\\\" value=\\\"%new_value\\\""

  param 'user'
  script 'lib/python/myscript.py', '-h' => 'host.com', '-u' => '%user'
end
```

Replacement values are specified in the `#start` call:

```ruby
proxy('parameter_example').start 'new_value' => '20', 'user' => 'user2'
```

#### Config inheritance
It is possible to add scripts and parameters to a proxy configuration by 'inheriting' from previously defined configs:

```ruby
mitmdump :default do
  strip_encoding
end
=> #<Mitmdump:0x007fc321abed48 @name=:default, @port=8080, @output="dumps/mitm.dump", @scripts=[[".../strip_encoding.py", {}]], @params={}>

mitmdump :extend do
  inherit :default
  param 'new_value'
  replace '\/application_config\.js',
    :swap => 'name=\"timeout\" value=\"\d+\"',
    :with => "name=\\\"timeout\\\" value=\\\"%new_value\\\""
end
=> #<Mitmdump:0x007fc321b9c6c0 @name=:extend, @port=8080, @output="dumps/mitm.dump", @scripts=[[".../strip_encoding.py", {}], [".../replace.py", {"-p"=>"\\/application_config\\.js", "-x"=>"name=\\\"timeout\\\" value=\\\"\\d+\\\"", "-r"=>"name=\\\"timeout\\\" value=\\\"%new_value\\\""}]], @params={"%new_value"=>""}>

mitmdump :extend2 do
  inherit :extend
  blacklist '\/'
end
=> #<Mitmdump:0x007fc321bcdc70 @name=:extend2, @port=8080, @output="dumps/mitm.dump", @scripts=[[".../strip_encoding.py", {}], [".../replace.py", {"-p"=>"\\/application_config\\.js", "-x"=>"name=\\\"timeout\\\" value=\\\"\\d+\\\"", "-r"=>"name=\\\"timeout\\\" value=\\\"%new_value\\\""}], [".../blacklist.py", {"-p"=>"\\/"}]], @params={"%new_value"=>""}>
```

### Other public methods

`#dumpfile` - returns the location of the mitmdump flow dump

### Example Cucumber integration
Define your proxy configurations in _./features/support/mitm/config.mitm_:
```ruby
mitmdump :default do
  strip_encoding 
  # by inheriting :default in all other proxies, compression can be turned off globally
end
.
.
.
```

Load your proxy config definitions in _./features/support/env.rb_:
```ruby
load_proxies('./features/support/mitm/config.mitm')
```

Define a step definition similar to the following:
```ruby
When(/^I use (\S*)\s*proxy( with \s*(.+\s*=\s*[^,\s]+),?)?$/) do |p, _, args| 
  h = args ? Hash[*args.gsub(/\s+|"|'/, '').split(/,|=/)] : {}
  p = 'default' if p == ''
  $mitm = proxy p.to_sym
  $mitm.start(h)
end
```

Example steps matching this step definition:
```cucumber
When I use proxy

When I use custom proxy

When I use custom proxy with new_value = 20

When I use custom proxy with new_value = 20, user = 'user2', host = "my.host.com"
```

Finally, stop the proxy at the end of the scenario in the __After__ hook (conventionally specified in _./features/support/hooks.rb_):

```ruby
After do |scenario|
  $mitm.stop if $mitm
end
```

## Reading from an mitmdump output file

### MitmdumpReader
`MitmdumpReader` enables reading from an mitmdump output file to JavaScript Object Notation (JSON).

```ruby
reader = MitmdumpReader.new(proxy('default').dumpfile)
reader.get_flows_from_file    # returns an array of all flows in file in JSON format
reader.get_requests_from_file    # returns an array of all requests in file in JSON format
reader.get_responses_from_file    # returns an array of all responses in file in JSON format
```

If you need to run validations or queries on the contents of the dumpfile it is generally more practical to use `MitmFlowArray` instead of `MitmdumpReader`. `MitmdumpReader` is just a Ruby integration layer for a Python program that parses the __mitmdump__ output file format into JSON.

### MitmFlowArray
`MitmFlowArray` provides utility methods for filtering the recorded flows by one or more conditions and returning specific values from the JSON. [JSONPath][9] is used to achieve this.

```ruby
f = MitmFlowArray.from_file(proxy('p1').dumpfile)
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
[10]: http://en.wikipedia.org/wiki/Glob_(programming)