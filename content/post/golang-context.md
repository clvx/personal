+++
author = "Luis Michael Ibarra"
title = "Golang Context"
date = "2021-02-09"
tags = [
    "golang",
    "context",
    "goroutine",
    "cancel",
]
+++

Checking about how to cancel requests I stepped onto the context package in golang. 

> Package context defines the Context type, which carries deadlines, cancellation signals,
and other request-scoped values across API boundaries and between processes.

```
type Context interface {

    Deadline() (deadline time.Time, ok bool)
    Done() <- chan struct{}
    Err() error
    Value(key interface{}) interface{}


}
```

Context allows to cancel any work that is being done using timeouts or by external
signals. This cancellation can be propagated to any function or goroutine that is
using the context.

Context manages a tree like structure having a root context and creating derived 
contexts based on the root context when you execute functions: `WithCancel`, 
`WithDeadline` and `WithTimeout`. Each function also returns a `CancelFunc` 
which returns a new `Done` channel that is closed when the parent context's `Done` 
channel is closed. In other words, when a Context is canceled, all Contexts derived from 
it are also canceled. It's important that any cancel function returned from a derived 
context is executed before that function returns. Not doing this will cause memory
leaks in your program.

Context per se doesn't have a cancel method:

> A Context does not have a Cancel method for the same reason the Done channel is 
receive-only: the function receiving a cancelation signal is usually not the one 
that sends the signal. In particular, when a parent operation starts goroutines for
sub-operations, those sub-operations should not be able to cancel the parent. Instead,
the WithCancel function provides a way to cancel a new Context value.

The main difference between `WithCancel` and `WithDeadline`/`WithTimeout` is that any 
cancellation made by the client will throw a _context cancelled_, but if the 
time expires then it will be _context deadline exceeded_.
Context cancelled is always cause by an upstream client, while deadline could be 
defined in one of the child functions.

The Context package also provides `WithValue`. This function allows to return a copy
of the parent Context with an associated value. This value MUST be a comparable key
of their own type. DO NOT USE concrete values.
It's only recommended to store request-scoped values. DO NOT store parameters that 
the function require to do its work.

The `context.Background` returns a non-nil, empty Context. It is never canceled, 
has no values, and has no deadline. It's used as initialization and considered 
the root Context.

## Best practices

- Incoming requests to a server should create a context.
- Outgoing calls to servers should accept a context.
- Do not store contexts inside a struct type.
- The chain of cuntion calls between them must propagate the context.
- Replace a context using `WithCancel`, `WithDeadline`, `WithTimeout`, `WithValue`
- When a context is cancelled, all contexts derived from it are also canceled.
- Do not pass a nil context. Pass a `context.TODO` if you are unsure about which context to use.
- Use context values only for request-scoped data that transits processes and api's,
not for passing optional parameters to functions.
- Debugging or tracing data is safe to pass in a context.

## Some code


    $cat main.go
    package main

    import (
        "net/http"

        "github.com/julienschmidt/httprouter"
    )

    func main() {
        router := httprouter.New()
        router.GET("/context/cancel/:delay", hedgedFunc)
        router.GET("/context/cancel", hedgedFunc)
        router.GET("/context/timeout/:delay", timeoutFunc)
        router.GET("/context/timeout", timeoutFunc)
        http.ListenAndServe(":8080", uuidMiddleware(router))
    }

The above code shows all the routes for the application. After running this code, 
you can call it:

    $curl localhost:8080/context/cancel         #default delay of 50ms
    $curl localhost:8080/context/cance/100      #delay of 100ms
    $curl localhost:8080/context/timeout        #default delay of 50ms
    $curl localhost:8080/context/timeout/500    #delay of 500ms

`hedgedFunc()` triggers hedged requests cancelling all the other goroutines after one
of the requests finishes. This function presents the `context.WithCancel()` logic.

`timeoutFunc` makes requests to a set of urls in sequential order. If the function 
does not finish in the desire timeout, it cancels the context exiting finishing the 
execution. This function presents the `context.WithTimeout`logic.

`uuidMiddleware()` provides a middleware to add a request-scoped UUID 
to identify the request using context values. This function presents the `context.WithValue` logic.

Finally, all these contexts examples are derivative of `http.Request.Context` which 
is the root context for the request.


    $cat hedged.go
    package main

    import (
        "context"
        "fmt"
        "io/ioutil"
        "log"
        "net/http"
        neturl "net/url"
        "strconv"
        "time"

        uuid "github.com/google/uuid"
        "github.com/julienschmidt/httprouter"
    )

    var urls = []string{
        "http://www.example.com",
        "http://blog.bitclvx.com",
    }
    var timeout time.Duration

    func getDelay(p httprouter.Params) (time.Duration, error) {
        if p.ByName("delay") != "" {
            delay, err := strconv.Atoi(p.ByName("delay"))
            if err != nil {
                return 0, err
            }
            return time.Duration(delay), nil
        }
        return time.Duration(50), nil
    }

    func hedgedFunc(w http.ResponseWriter, r *http.Request, param httprouter.Params) {
        timeout, err := getDelay(param)
        if err != nil {
            w.WriteHeader(http.StatusNotFound)
            return
        }
        ch := make(chan string, len(urls))
        ctx, cancel := context.WithCancel(r.Context())
        defer cancel()
        for _, url := range urls {
            go func(u string, c chan string) {
                c <- executeQueryWithContext(u, ctx)
            }(url, ch)

            select {
            case result := <-ch: //if channel returns, cancel context, and return results
                fmt.Fprint(w, result)
                cancel()
            case <-time.After(timeout * time.Millisecond): //wait 21ms before making another request
            }
        }
    }

    func executeQueryWithContext(url string, ctx context.Context) string {
        start := time.Now()
        parsedUrl, _ := neturl.Parse(url)
        req := &http.Request{URL: parsedUrl}
        req = req.WithContext(ctx) //execute query with context.

        response, err := http.DefaultClient.Do(req)

        if err != nil {
            fmt.Println(err.Error())
            return err.Error()
        }

        defer response.Body.Close()
        body, _ := ioutil.ReadAll(response.Body)
        log.Printf("[%v] - Request time: %d ms from url%s\n", ctx.Value("uuid"), time.Since(start).Nanoseconds()/time.Millisecond.Nanoseconds(), url)
        return fmt.Sprintf("%s from %s", body, url)
    }

    func timeoutFunc(w http.ResponseWriter, r *http.Request, param httprouter.Params) {
        timeout, err := getDelay(param)
        if err != nil {
            w.WriteHeader(http.StatusNotFound)
            return
        }
        ctx, cancel := context.WithTimeout(r.Context(), time.Duration(timeout)*time.Millisecond)
        defer cancel()
        for _, url := range urls {
            executeQueryWithContext(url, ctx)
        }
        return
    }

    func uuidMiddleware(next http.Handler) http.Handler {
        return http.HandlerFunc(
            func(w http.ResponseWriter, r *http.Request) {
                uuid := uuid.New()
                r = r.WithContext(context.WithValue(r.Context(), "uuid", uuid))
                next.ServeHTTP(w, r)
            })
    }


## Bibliography

- https://golang.org/pkg/context
- https://www.ardanlabs.com/blog/2019/09/context-package-semantics-in-go.html
- https://blog.golang.org/context
- https://medium.com/swlh/hedged-requests-tackling-tail-latency-9cea0a05f577
