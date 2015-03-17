noms
====

**noms** is a remote command-line interface interpreter. It's designed to be a stable runtime environment for interpreting server-defined command-line interfaces for (principally) rest-like data stores (or for commands that are side-effect free, but *not* commands that change any state on the system on which the command runs).

The web browser is a platform in which the operator of a web service can implement a graphical user interface to data it controls. For example, it's a common pattern to offer access to services and data via a ReST or ReST-like interface, making http requests against a remote API understanding the HTTP verbs and returning results in the form of HTTP responses, header metadata and response bodies containing serialized data (e.g. JSON). Such interfaces are generally implemented in a combination of HTML documents and Javascript which modifies the document model of the HTML page(s).

**noms** enables an author to offer a command-line interface designed along the same pattern: structured documents modified by javascript programs, interpreted and rendered on the client. **noms** has sandboxing similar to web browsers (no modifying of local storage outside of restricted, application-specific local storage and automatic caching of javascript files).

**noms** is *not* a web browser and is not designed to offer terminal user interfaces like lynx or elinks. It is also *not* an interactive shell--it's designed to be used from a shell. It maintains authenticated sessions state when necessary.

Syntax
------

The basic way of invoking an **noms** command is as follows::

  noms *url* *options* *arguments*

**noms** invokes the app at *url* with the given options and arguments, displaying the results.

Bookmarks
~~~~~~~~~

* ``noms *bookmark*[/arg] ...``

The **noms** command itself has a configuration file (``~/.noms``, ``/usr/local/etc/noms.conf``, ``/etc/noms.conf`` in that order) which defines bookmarks to different URLs. For example, given the following in ``/etc/noms.conf``::

  { 
    "cmdb": "https://cmdb.noms-example.com/cmdb.json",
    "instance": "https://ncc-api.noms-example.com/ncc-api.json",
    "nagios": "https://nagios.noms-example.com/nagui.json",
    "nag": "https://nagios.noms-exmaple.com/nagui.json"
  }

When invoked in the following ways, it's the equivalent to the command on the right:

================================= ==================================================================
Command given                     Equivalent command
================================= ==================================================================
``noms cmdb query fqdn~^m00``     ``noms https://cmdb.noms-example.com/cmdb.json query fqdn~^m00``
                                  (``document.argv[0]`` set to ``cmdb``)
``noms cmdb/env list``            ``noms https://cmdb.noms-example.com/cmdb.json list``
                                  (``document.argv[0]`` set to ``cmdb/env``)
``noms nag alerts``               ``noms https://cmdb.noms-example.com/nagui.json alerts``
                                  (``document.argv[0]`` set to ``nag``)
================================= ==================================================================

Implementation
--------------

If the type is ``text/*``, it's simply displayed.

If the type is a recognized data serialization format (``application/json`` or ``application/yaml``), it's parsed as structured data. If the fetched content is a single object and the object has the top-level key '$doctype', it may be interpreted according to `Dynamic Doctype`_, below. Otherwise, it is assumed to be either a single object to display or a list of such, and **noms** will render the object or array using its default format (usually YAML).

Dynamic Doctype
~~~~~~~~~~~~~~~

The principle dynamic doctype is the ``noms-v2``, which is an object with the following top-level attributes:

``$doctype``
  Must be ``noms-v2``. In future, backwards-incompatible extensions may be implemented in ``noms-v3`` or higher doctypes.

``$script``
  An ordered array of scripts to fetch and evaluate.

``$argv``
  The arguments passed to the application. It's called ``$argv`` because ``$argv[0]`` contains the name by which the application is invoked (that is, the bookmark or URL).

``$exitcode``
  The unix process exit code with which **noms** will exit at the completion of the command.

``$body``
  The body of the document is the data to display. See `Output Formatting`_ below.

From the perspective of javascript executing within the application, these are accessible as properties of the
global **document** object.

Output Formatting
~~~~~~~~~~~~~~~~~

The following entities are allowed in the body of a **noms-v2** document.

* Arrays - Each item in the array is concatenated with a line-break between them.
* Strings and numbers - A string or number is just displayed.
* Raw objects - Raw objects are rendered using **noms'** default formatting (usually YAML)
* Described objects - Described objects are data along with information on how to render them. A described object
  has a top-level attribute called **$type** which defines how the described object is rendered.

  * ``$type``: **object-list** An object list is a (usually) tabular list of objects with information on how
    wide to make the fields or how to otherwise serialize the objects. It has the following attributes:

    * **format**: The format in which to render, one of: **json**, **yaml**, **csv**, **lines** (default **lines**).
      The **lines** format is **noms'** built-in presentation of tabular data.
    * **columns**: An array of column specifiers. A column specifier is either a string with the name of
      the field to display, or an object which has the following attributes:
      * **field**: The object field to display in the column (*required*)
      * **heading**: The label to display in the column heading
      * **width**: The width of the column (data is space-padded to this width)
      * **align**: One of ``left`` or ``right``, determines data alignment within column
      * **maxwidth**: The maximum width of the data (values exceeding this length are truncated)
    * **labels**: Default ``true``; whether to display header row with field labels
    * **columns**: Field names, headings and widths
    * **data**: The objects to render

  * ``$type``: **object** An object has the following attributes:

    * **format**: The format in which to render, one of: **json**, **yaml**, **record** (default **record**).
      The **record** format is **noms'** built-in presentation of record data.
    * **fields**: The fields to display (default is all fields)
    * **labels**: Default ``true``, whether to display field labels
    * **data**: The object data

Javascript Environment
----------------------

Invoked scripts have access to the following global objects:

* **window** - This has information about the terminal environment in which **noms** is being invoked. It has the following attributes/methods:
  * **height** - Height (if known)
  * **width**  - Width (if known)
  * **isatty** - true if the output stream is a terminal
  * **document** - The document global object
  * **alert** - Produce output on the error stream :tag:`TODO`
* **document** - The document object is the current document being rendered by **noms**. In addition to the attributes of the document itself, it has the following:
  * **argv** - The arguments being invoked. The first element of this array is the first argument passed to **noms** itself (not the script it ultimately fetches, but how it's invoked, similar to ``$1``
  * **exitcode** - The numeric exit code with which **noms** will exit. Initially 0.
  * **body** - The text to display according to NOMS formattting.
* **XMLHttpRequest** - An implementation of the XMLHttpRequest interface.


Web 1.0 vs Web 2.0
------------------

Like the "real web", **noms** commands can choose to do some calculation on the server and some on the client: **noms** doesn't care. You can use no ``$script`` tag at all and just calculate the entire document to be rendered in the client (though this currently odoesn't allow for argument interpretation, in the future the arguments may be passed in request headers or **noms** may allow a way for them to show up in a query string or POST request--but **noms** is not really a command-line http client either). This is up to the application designer.

Example Application
-------------------

In the source code repository is an example **noms** application, **dnc** (a "do not call" list).
The following is an example session with **dnc**::

  bash$ noms http://localhost:8787/dnc.json
  Usage:
     noms dnc add <field>=<value> [<field>=<value> [...]]
     noms dnc remove <id>
     noms check { <phone> | <name> }
     noms list
  bash$ noms http://localhost:8787/dnc.json list
  name                 phone               
  Manuela Irwin        (817) 555-0427      
  Ronda Sheppard       (401) 555-0801      
  Leonor Foreman       (401) 555-0428      
  Emma Roman           (317) 555-0589      
  Frieda English       (312) 555-0930      
  Kitty Morton         (804) 555-0618      
  Kathy Mcleod         (607) 555-0052      
  Bettie Wolfe         (843) 555-0523      
  Vanessa Conway       (404) 555-0885      
  Ian Welch            (817) 555-0555      
  10 objects
  bash$ curl http://localhost:8787/dnc.json
  { "$doctype": "noms-v2",
    "$script": [{ "$source": "lib/commands.js" }],
    "$body": [
        "Usage:",
        "   noms dnc add <field>=<value> [<field>=<value> [...]]",
        "   noms dnc remove <id>",
        "   noms check { <phone> | <name> }",
        "   noms list"
    ]
  }
  bash$ curl http://localhost:8787/lib/commands.js
  if (document.argv.length > 1) {
    var command = document.argv[1];
    var xmlhttp = new XMLHttpRequest();

    switch(command) {
    case "list":
        // unimplemented callbacks
        xmlhttp.open("GET", "/dnc", false);
        xmlhttp.send();
        var records = eval('(' + xmlhttp.responseText + ')');
        // Set the 'output' to the format specifier that
        // tells noms to produce an object list output
        document.body = [
            {
                '$type': 'object-list',
                '$columns': [
                    { 'field': 'name', 'width': 20 },
                    { 'field': 'phone', 'width': 20 }
                ],
                '$data': records
            },
            records.length + " objects"
        ];
        break;
    default:
        document.exitcode = 8;
        // need errors and warnings
        document.body = [
            document.argv[0] + ": Unknown command '" + command + "'"
        ];
    }
  }
  bash$ curl http://localhost:8787/files/data.json
  [
  {"id":1,"name":"Manuela Irwin","street":"427 Maple Ln","city":"Arlington, TX  76010","phone":"(817) 555-0427"},
  {"id":2,"name":"Ronda Sheppard","street":"801 New First Rd","city":"Providence, RI  02940","phone":"(401) 555-0801"},
  {"id":3,"name":"Leonor Foreman","street":"428 Willow Rd","city":"Providence, RI  02940","phone":"(401) 555-0428"},
  {"id":4,"name":"Emma Roman","street":"589 Flanty Terr","city":"Anderson, IN  46018","phone":"(317) 555-0589"},
  {"id":5,"name":"Frieda English","street":"930 Stonehedge Blvd","city":"Chicago, IL  60607","phone":"(312) 555-0930"},
  {"id":6,"name":"Kitty Morton","street":"618 Manchester St","city":"Richmond, VA  23232","phone":"(804) 555-0618"},
  {"id":7,"name":"Kathy Mcleod","street":"52 Wommert Ln","city":"Binghamton, NY  13902","phone":"(607) 555-0052"},
  {"id":8,"name":"Bettie Wolfe","street":"523 Sharon Rd","city":"Coward, SC  29530","phone":"(843) 555-0523"},
  {"id":9,"name":"Vanessa Conway","street":"885 Old Pinbrick Dr","city":"Athens, GA  30601","phone":"(404) 555-0885"},
  {"id":10,"name":"Ian Welch","street":"555 Hamlet St","city":"Arlington, TX  76010","phone":"(817) 555-0555"}
  ]

The example application is a very simple sinatra REST API to a data store consisting of a JSON file, and the static files
comprising the Javascript source code and the **noms** application document.
