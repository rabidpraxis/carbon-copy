# Carbon Copy - Easily cache them REST calls

We created Carbon Copy to allow for quick front end (or back end) development by
caching REST responses.

### How it works

Install the gem

    gem install carbon-copy

Run the server with a specified port

    carbon-copy -p 8989

Alter your REST calls on the front-end to pipe them locally through carbon-copy

    $.get('http://localhost:8989/slow.server.com/resource')

On the first run, the requests will be cached in the `.request_cache` directory
in the same path as where you called the server. On subsequent requests, the
calls will pull from that cache instead of contacting the server.

You can restart the cache at any time by deleting the specific cache files.
