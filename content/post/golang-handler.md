+++
author = "Luis Michael Ibarra"
title = "Golang HTTP Handlers"
date = "2020-11-23"
tags = [
    "golang",
    "middleware",
    "http",
    "handlers",
    "mux",
]
+++

To process HTTP requests in golang, you need a way to handle different routes, 
and a actual handler to process the requests. ServeMux and the Handler interface 
do exactly that.

## Handler Interface

Golang provides the `http.Handler` interface to respond to HTTP requests in the 
`net/http` package. This interface only requires you to implement 
`ServeHTTP(ResponseWriter, *Request)`.

    type Handler interface {
        ServeHTTP(ResponseWriter, *Request)
    }

In addition, the `http.HandlerFunc` type is an adapter to allow the use of
 ordinary functions as HTTP handlers.

    type HandlerFunc func(ResponseWriter, *Request)

    // ServeHTTP calls f(w, r).
    func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
        f(w, r)
    }

For example, the following call will implement the Handler interface.

    http.HandlerFunc(func (w http.ResponseWriter, r \*http.Request){
        w.Write([]byte("Hola Mundo"))
    })

## ServeMux

ServeMux is a HTTP request multiplexer which means it matches incoming requests with
a list of registered patterns. You can create one by calling `http.NewServeMux()` 
which returns a pointer to a `ServeMux` struct. There's also `DefaultServeMux` which is 
a global defined `ServeMux` in case you don't specify one. As it's a global variable
any package is able to access it and register a route in it. 

`ServeMux` provides a bunch of methods, but the most important ones are 
`ServeMux.Handle`, `ServeMux.HandleFunc`, and `ServeMux.ServeHTTP`. 

    ServeMux.Handle(pattern string, handler Handler)
    ServerMux.HandleFunc(pattern string, handler func(http.ResponseWriter, \*http.Request)

Both functions register a pattern for the given handler in `http.ServerMux.MuxEntry` 
 struct, but `ServeMux.HandleFunc` calls `ServeMux.Handle` internally passing the 
`http.HandlerFunc(pattern, handler)` function as a parameter.

`ServeMux.ServeHTTP` implements the Handler interface.

    type customHandler struct{}

    //implementing the Handler interface
    func (mh *customHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("custom handler!"))
    }

    func myHome (w http.ResponseWriter, r *http.Request){
        w.Write([]byte("another custom handler!"))
    }

    func main() {
        myHandler := customHandler{}

        mux := http.NewServeMux()
        mux.Handle("/", myHandler) //registers / to myHandler
        mux.HandleFunc("/home", myHome) //registers /home to myHome

        http.ListenAndServe(":3000", mux) //uses custom mux
        http.ListenAndServe(":4000", nil) //uses DefaultServeMux
    }

## Middleware 

Middleware is used to provide a processing pipeline separating concerns and defining
clear boundaries for a request lifecycle.

It's achieved by creating a chain of handlers to do pre or post procesing.

    func exampleMiddleware(next http.Handler) http.Handler {
        return http.HandlerFunc(
            func (w http.ResponseWriter, r *http.Request) {
                //pipeline pre processing
                next.ServeHTTP(w, r)
                //pipeline post processing
            }
        )
    }

The above example has a handler interface as a signature and returns a handler. 
This means it can be used with `http.ServeMux` or any other object that implements 
the Handler interface. Furthermore, as it returns a Handler interface, it can be 
chained with objects that expect one.

### Injecting dependencies - Adapter

We can use an adapter to pass dependencies to our middleware function. The dependencies
will be available to the closure. As we are wrapping the middleware in a closure, 
it can be extendend with different variables.

    func exampleMiddlewareDependency(key, val string) func(http.Handler) http.Handler {
        return func(next http.Handler) http.Handler {
            //returns a handler interface
            return http.HandlerFunc(
                func (w http.ResponseWriter, r *http.Request) {
                    //pipeline pre processing
                    w.Header().Add(key, val)
                    next.ServeHTTP(w, r)
                    //pipeline post processing
                }
            )
        }
    }

We can call later the function as

     func main() {
        myHandler := customHandler{}

        mux := http.NewServeMux()
        mux.Handle("/", myHandler) //registers / to myHandler
        mux.HandleFunc("/home", myHome) //registers /home to myHome

        middleware := exampleMiddlewareDependency("foo", "bar") //returns a func(http.Handler) http.Handler

        http.ListenAndServe(":3000", middleware(mux)) //wrapping mux in middleware
    }
   

### Injecting dependencies - Types

Another way to pass dependencies is defining a struct that implements the Handler 
interface defining a handler and any other variables as elements.

    type middlewareHandler struct {
        next     http.Handler
        headerKey   string
        headerValue string
    }

    func(mh *middlewareHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) http.Handler{
        w.Header().Add(key, val)
        mh.next.ServeHTTP(w, r)
    }

    func newMiddlewareHandler(next http.Handler, key string, value string) *middlewareHandler{
        return &middlewareHandler{next, key, value}
    }

      func main() {
        myHandler := customHandler{}

        mux := http.NewServeMux()
        mux.Handle("/", myHandler) //registers / to myHandler
        mux.HandleFunc("/home", myHome) //registers /home to myHome

        middleware := newMiddlewareHandler(mux, "foo", "bar")
        http.ListenAndServe(":3000", middleware) //wrapping mux in middleware
    }   

## Bibliography

- https://medium.com/better-programming/overview-of-server-side-http-apis-in-go-44f052737e4b
- https://stackoverflow.com/questions/40478027/what-is-an-http-request-multiplexer
- https://www.alexedwards.net/blog/a-recap-of-request-handling
- https://drstearns.github.io/tutorials/gohandlerctx/#secclosures
