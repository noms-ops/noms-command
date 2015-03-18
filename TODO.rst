TODO
====

* Finish XMLHttpRequest() implementation (async calls, other HTTP methods)
  * Well, XMLHttpRequest has an interface with a ``.send()`` method. This
    interferes quite strongly with Ruby's **Object#send** and the V8
    calling convention (methodcall) where you have to supply an explicit
    invocant. Possibly I can find a way to work around and use call() or
    duplicate it in the way that TRR adds ``:methodcall``; if not, I
    may have to wrap XMLHttpRequest in a Javascript constructor.
* Javascript errors: file (and line number/expression?)
* Javascript objects: ``console``, ``location``
* Flesh out example application
