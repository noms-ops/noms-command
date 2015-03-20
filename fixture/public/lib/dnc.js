if (document.argv.length > 1) {
    var argv = document.argv;
    var me = argv.shift();
    var format;
    var xmlhttp = new XMLHttpRequest();

    var optspec = [
        ["-J", "--json", "Display JSON"],
        ["-Y", "--yaml", "Display YAML"],
        ["-C", "--csv", "Display CSV"],
        ["-v", "--verbose", "Enable verbose output"],
        ["-q", "--terse", "Use terse output"],
        ["--nofeedback", "Don't print feedback"],
        ["--nolabel", "Don't print field names"],
        ["--noheader", "Don't print column headings"]
    ];

    // document attributes can be set
    // but are immutable
    document.body = [ ];
    var output = [ ];

    var parser = new optparse.OptionParser(optspec);
    var options = {
        "format": "default",
        "verbose": false,
        "feedback": true,
        "label": true,
    };

    var field_config = {
        'id':      { 'field': 'id', 'width': 3, 'align': 'right' },
        'name':    { 'field': 'name', 'width': 20 },
        'phone':   { 'field': 'phone', 'width': 20 },
        'street':  { 'field': 'street', 'width': 40 },
        'city':    { 'field': 'city', 'width': 31 }
    }

    parser.on("verbose", function() { options["verbose"] = true; });
    parser.on("json", function() {
        options["format"] = "json";
        options["feedback"] = false;
    });
    parser.on("yaml", function() {
        options["format"] = "yaml";
        options["feedback"] = false;
    });
    parser.on("csv", function() {
        options["format"] = "csv";
        options["feedback"] = false;
    });
    parser.on("nofeedback", function() { options["feedback"] = false; });
    parser.on("nolabel", function() { options["label"] = false; });
    parser.on("terse", function() {
        options["feedback"] = false;
        options["label"] = false;
    });
    // parser.on(0, function(arg) { command = arg; });

    var args = parser.parse(argv);
    var command = args.shift();

    var format, records, field_list;

    switch(command) {

    case "add":
        var keywords = new nomsargs.NomsArgs(args);

        xmlhttp.open("POST", "/dnc", false);
        xmlhttp.setRequestHeader("Content-type", "application/json");
        xmlhttp.send(JSON.stringify(keywords.assignment));

        if (xmlhttp.status == 201) {
            record = JSON.parse(xmlhttp.responseText);
            output.push("Entry created with id " + record['id']);
        } else {
            alert("Error " + xmlhttp.status + " creating entry");
            document.exitcode = 2;
        }

        break;

    case "remove":
        var id = args.shift();

        if (id == undefined) {
            alert("No id to remove");
            document.exitcode = 1;
        } else {
            xmlhttp.open("DELETE", "/dnc/" + id, false);
            xmlhttp.send();

            if (xmlhttp.status == 404) {
                alert("Entry " + id + " does not exist");
            } else if (xmlhttp.status != 204) {
                alert("Error deleting id " + id);
                document.exitcode = 2;
            }
        }

        break;

    case "set":
        // We are not doing upsert
        var id = args.shift();
        var keywords = new nomsargs.NomsArgs(args);

        if (id == undefined) {
            alert("No id to set");
            document.exitcode = 1;
        } else {
            xmlhttp.open("GET", "/dnc/" + id, false);
            xmlhttp.send();

            if (xmlhttp.status == 404) {
                alert("Entry " + id + " does not exist (use add)");
                document.exitcode = 2;
            } else if (xmlhttp.status == 200) {
                the_object = JSON.parse(xmlhttp.responseText);

                // Update assigned fields in retrieved object
                keywords.assignmentKeys().map(function (key) {
                    the_object[key] = keywords.assignment[key];
                });

                xmlhttp.open("PUT", "/dnc/" + id, false);
                xmlhttp.send(JSON.stringify(the_object));

                if (xmlhttp.status == 200) {
                    output.push("Entry " + id + " updated");
                } else {
                    alert("Error " + xmlhttp.status + " updating entry " + id);
                    document.exitcode = 2;
                }
            }
        }

        break;

    case "show":
        var id = args.shift();
        var field_list = args;
        format = (options["format"] == "default" ? "record" : options["format"]);

        if (id == undefined) {
            alert("No id to show");
            document.exitcode = 1;
        } else {
            xmlhttp.open("GET", "/dnc/" + id, false);
            xmlhttp.send();

            if (xmlhttp.status == 404) {
                alert("Entry " + id + " not found");
                document.exitcode = 2;
            } else {
                console.log("output for record");
                record = JSON.parse(xmlhttp.responseText);

                console.log(record);

                output.push({
                    '$type': 'object',
                    '$format': format,
                    '$labels': options["label"],
                    '$fields': field_list,
                    '$data': record
                });
            }
        }

        break;

    case "query":
        var keywords = new nomsargs.NomsArgs(args);
        format = (options["format"] == "default" ? "lines" : options["format"]);
        var query = keywords.query();
        var field_list = keywords.extra;

        if (field_list.length == 0) {
            field_list = ['id', 'name', 'phone'];
        }
        xmlhttp.open("GET", "/dnc?" + query, false);
        xmlhttp.send();
        records = JSON.parse(xmlhttp.responseText);

        output.push(
            {
                '$type': 'object-list',
                '$format': format,
                '$labels': options["label"],
                '$columns': field_list.map(function(item) { return field_config[item]; }),
                '$data': records
            });
        if (options["feedback"]) {
            output.push(records.length + " objects");
        }
        break;

    case "list":
        format = (options["format"] == "default" ? "lines" : options["format"]);

        xmlhttp.open("GET", "/dnc", false);
        xmlhttp.send();
        records = JSON.parse(xmlhttp.responseText);
        field_list = (args.length == 0 ? ['id', 'name', 'phone'] : args)
        output.push(
            {
                '$type': 'object-list',
                '$format': format,
                '$labels': options["label"],
                '$columns': field_list.map(function(item) { return field_config[item]; }),
                '$data': records
            });
        if (options["feedback"]) {
            output.push(records.length + " objects");
        }
        break;

    default:
        document.exitcode = 8;
        window.alert(
            me + " error: Unknown command '" + command + "'"
        );
    }

    document.body = output;
}
