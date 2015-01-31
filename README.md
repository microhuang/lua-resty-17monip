# lua-resty-17monip

lua-resty-17monip - 17MonIP parsing library for ngx_lua.

# Status

Ready for testing. Probably production ready in most cases, though not yet proven in the wild. Please check the issues list and let me know if you have any problems / questions.

## Description

IP query based on [17mon.cn](http://tool.17mon.cn/), the best IP database for China.

## Synopsis

````lua
lua_package_path "/path/to/lua-resty-17monip/lib/?.lua;;";

init_by_lua '
    local monip = require "resty.17monip"
    iplocater = monip:new{ datfile = "t/17monipdb.dat" }
';

server {

    listen 9090;

    location /t {
        content_by_lua '
            local iplocater = iplocater
            local res, err = iplocater:query("115.216.25.67")
            if not res then
                ngx.say(err)
                return
            end
            ngx.say(res[1], " ", res[2], " ", res[3])
        ';
    }

}
````

A typical output of the `/t` location defined above is:

```
中国 浙江 宁波
```

# Methods

## new

`syntax: iplocater, err = monip:new(opts?)`

Initialize the IP locater object. In case of failures, returns `nil` and a string describing the error.

The `opts` table accepts the following fields:

* `datfile`: Sets the 17monipdb.dat ([download free version](http://s.qdcdn.com/17mon/17monipdb.zip)) file path.
* `data`: Sets the binary data as database source.

## update

`syntax: ok, err = iplocater:update(opts?)`

Update the IP database.

The `opts` table as same as the `monip:new` method.

In case of failures, returns `nil` and a string describing the error.

## query

`syntax: res, err = iplocater:query(ip)`

Query location by IP address.

In case of errors, returns `nil` with a string describing the error.

# Author

Monkey Zhang <timebug.info@gmail.com>, UPYUN Inc.

# Licence

This module is licensed under the 2-clause BSD license.

Copyright (c) 2014, Monkey Zhang <timebug.info@gmail.com>, UPYUN Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
