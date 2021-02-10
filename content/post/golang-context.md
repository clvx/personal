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

## Context

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

## Bibliography

- https://golang.org/pkg/context
- https://www.ardanlabs.com/blog/2019/09/context-package-semantics-in-go.html
- https://blog.golang.org/context
