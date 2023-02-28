# Spillway

Load shedding is a technique for resiliency in the face service overload, recommended by Google [1] and Amazon [2] for operating highly available systems.
When the incoming requests exceed the capacity of the servers,
load shedding drops a portion of requests in order to maintain qualtiy of service for the remaining requests.

Spillway is a turnkey Docker HTTP proxy with load shedding.
Requests are let through up to a set concurrency limit,
after which they are queued up until capacity is available or the queue timeout is hit.
Health checks can be configured to skip the queue,
so they will succeed as long as the application is responding to HTTP requests

1. [Site Reliability Engineering: How Google Runs Production Systems, Chapter 22: Addressing Cascading Failures](https://landing.google.com/sre/sre-book/chapters/addressing-cascading-failures/#xref_cascading-failure_load-shed-graceful-degredation)
2. ["Using load shedding to avoid overload," Amazon Builders Library](https://aws.amazon.com/builders-library/using-load-shedding-to-avoid-overload/)

## Why Load Shed?

Let's say that you operate a service that can handle 1000 requests per second.
A spike in demand causes 1500 requests per second to be sent to the service.
After 10 seconds, 5000 requests have not yet been fulfilled.
Any new request will need to wait for the existing 5000 requests to be processed—An additional five seconds of latency.
After a minute, latency is up to 30 seconds.
Let's say the clients have a 30 second timeout.
At this point, any request being processed will not return to the client before the timeout is hit and the work is wasted.
Even though the server is still processing 1000 requests per second,
the number of useful requests being processed per second—The "goodput," as Amazon calls it—goes to zero.

If the client has retry logic (or impatient users mashing buttons), duplicate requests are sent, increasing the load and exacerbating the problem.
Health checks may start to fail and "failing" machines are taken out of service, increasing the load on the remaining machines.
Even if the initial spike in demand subsides, these adverse conditions may cause the service overload to persist.

With Spillway's load shedding, requests queued for too long error out.
Not all requests are successful, but the requests that are successful return quickly enough to be useful.
Health checks will continue to succeed, so machines will continue to server requests.

This is not some concern only of Google-scale services.
I personally have had demand spikes on modestly-sized services turn into full-blown outages due to a lack of load shedding.

## Getting Started

Spillway can be found in Docker Hub as [luhn/spillway:1.0](https://hub.docker.com/r/luhn/spillway)
and AWS ECR as [public.ecr.aws/luhn/spillway:1.0](https://gallery.ecr.aws/luhn/spillway).
You can download the source code from [github.com/luhn/spillway](https://github.com/luhn/spillway/).

Spillway requires two command-line arguments:

* The address of the app server.
* The concurrency level.

For example, you might run Spillway with the following Docker command:

```bash
docker run -p 8000:8000 --link app luhn/spillway app:8080 3
```

Spillway will accept requests on port 8000 and forward them to `app:8080`.
If more than three requests are inflight at a time, additional requests will be queued until availability opens up.

## Configuration

Spillway can be configured via environment variables.

* `MAX_CONNECTIONS` — The maximum number of connections that can be open at a single time.  Defaults to 2000.
* `QUEUE_TIMEOUT` — The time in milliseconds before a request times out in the queue.  Defaults to five seconds.
* `SERVER_TIMEOUT` — The time in milliseconds a request can be processed by the server before it times out.  Defaults to 30 seconds.
* `PORT` — The port to bind to.  Defaults to 8000.
* `HEALTHCHECK_PATH` — Requests matching this path will skip the queue.  Defaults to `/healthcheck`.
* `LOG_ADDRESS` — A syslog server to log to.  See below for more details.
* `LOG_FORMAT` — See below.

## Logging

Requests can be logged by setting the `LOG_ADDRESS` environment variable to a syslog server.
Can also be set to `stdout` or `stderr`.

The log format is:

```
[backend] [status] [depth] [queue time]/[response time]
```

* *backend* — One of `app` or `healthcheck`, indicating if it was a standard request or a healthcheck.
* *status* — The HTTP status code returned.
* *depth* — The queue depth, i.e. the number of requests processed before this one.
* *queue time* — The time in milliseconds the request waited in the queue.
* *response time* — The time in milliseconds for the application to respond.

For example:

```
app 200 3 14/34
```

The log format can be customized by setting the `LOG_FORMAT` environment variable.
See the [HAProxy docs](http://cbonte.github.io/haproxy-dconv/2.1/configuration.html#8.2.4)
for how to write a custom log format.

## Limitations

Spillway does not buffer HTTP requests, so it's recommended to put it behind a load balancer or reverse proxy such as nginx.
For a turnkey Docker reverse proxy, check out [docker-gunicorn-proxy](https://hub.docker.com/r/luhn/gunicorn-proxy).
