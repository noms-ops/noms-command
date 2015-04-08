noms-command Roadmap
====================

Roadmap
-------

These items are necessary and a fairly well-identified goal.

Authentication
~~~~~~~~~~~~~~

Authentication needs to be handled in a rich and correct way. One of
the original inspirations for replacing the **noms** v1 thick client
was the daunting nature of adding authentication code to all the different
client libraries for the NOMS_ components and then exposing an interface
to dealing with them to the command-line.

Instead, all the web plumbing and dealing with things like how to
present persistent web sessions to a user are going to be handled by the
general purpose web application client **noms**, and services like the
NOMS CMDB, NCC-API, NagUI-API, etc. can provide their own command-line
implementations. The NOMS_ components are likely to use standard Javascript
libraries to present a consistent look, feel and implementation, but
**noms** will provide the ability for a service provider to define a CLI
that looks and feels any way they want.

That means **noms** should be good at command-line web authentication. The
old v1 client could not do more than Basic authentication, and this necessitated
the storage of personal credentials in plaintext on the system, mixed with
other configuration like the ReST enpoint URLs and usage conveniences like
default values.

Instead **noms** will handle many authentication flavors in a way that is
as secure as possible:

============================ =====================================================
Authentication Type          Description
============================ =====================================================
Username/password (basic,    **noms** will prompt the user for credentials when
digest)                      receives the authorization required HTTP status, and
                             persist the result in an obfuscated, expiring form
                             for that origin.
---------------------------- -----------------------------------------------------
Login URL with cookie-based  **noms** honors redirects to a login URL in the
sessions                     same way as a web browser and stores cookies
                             using proper cookie expiration. **noms** doesn't
                             do HTML parsing, so authentication on the login
                             URL must be of some other type or scriptable
                             with Javascript.

                             This implies that Javascript must be able to
                             script the authentication dialog, which means
                             there must be some way to do prompting; currently
                             this can use the ``window.prompt()`` interface.
---------------------------- -----------------------------------------------------
Login URL with special token **noms** will offer a way for javascripts to persist
to be included in request    state across requests. This mechanism will allow
headers                      a javascript to set special headers or request
                             tokens that it will have access to for later
                             requests.

                             This will use the WebStorage API.
---------------------------- -----------------------------------------------------
Login URL with special token Similar to above, with a somewhat different request
to be included in request    implementation.
bodies
---------------------------- -----------------------------------------------------
OAuth                        **noms** may use httpclient's built-in OAuth
                             and prompt the user to authenticate with OAuth, and
                             use the OAuth token for subsequent requests.
---------------------------- -----------------------------------------------------
Client certificate           Prompt for passphrase or use authentication agent
                             to provide client certificate.
============================ =====================================================

Storage
~~~~~~~

In order to persist state across requests, **noms** should probably
have a `Web Storage`_ implementation.

.. _`Web Storage`: http://dev.w3.org/html5/webstorage/

Crossroads
----------

The following is not a roadmap, but a series of ideas of how **noms**
could be enhanced as well as unanswered questions about how it should
work.

I/O
~~~

Its prototype does no local I/O. Outside of restricted situations like
`Web Storage`_ this is probably desirable. It's extremely typical of CLIs, even
those for "remote" data stores, to be able to do some I/O, and here are a couple
of ideas how:

* stdin - Right now there's no way to even read stdin. So if you want to make a
  CLI for uploading batch data you can't even do it--your scripts only have access
  to command-line arguments.

  Use HTML5 FileReader API to have access to stdin, probably through
  ``windows.stdin``.

Another thing is the possibility of doing I/O on select named files. **noms** could
perhaps pre-parse the command line and add the files mentioned on the command line
to an ACL which would allow downloaded scripts to access them. For example::

  noms http://cmdb/cmdb.json generate-ansible-inventory --output=inventory.json

**noms** could scan the command line and guess at what files the user intends the
application to have access to, and allow the Javascript to open them using a node.js-like
stream implementation. Exactly how to do this safely would be a challenge. Are only
certain options allowed? Files that already exist (otherwise it would be easy to allow
the script to write to unintended files). No files with '..'? What about -oFile.json
vs. -onf?

This seems like something that's too easy to get very wrong.

Another I/O-related subject is that **noms** is currently completely request/response-
oriented. It might be nice to be able to stream output data, or input data for file-
or batch-upload type operations, or wait for events on a websocket.
