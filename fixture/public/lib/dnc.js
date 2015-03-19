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
        ["--nofeedback", "Don't print feedback"]
    ];

    // document attributes can be set
    // but are immutable
    document.body = [ ];
    var output = [ ];

    var parser = new optparse.OptionParser(optspec);
    var options = {
        "feedback": true,
        "format": "default",
        "verbose": false
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
    // parser.on(0, function(arg) { command = arg; });

    var args = parser.parse(argv);
    var command = args.shift();

    var format, records, field_list;

    switch(command) {

    case "query":
        var keywords = new nomsargs.NomsArgs(args);
        format = (options["format"] == "default" ? "lines" : options["format"]);
        field_list = [ ];
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
        console.log(args);
        field_list = (args.length == 0 ? ['id', 'name', 'phone'] : args)
        output.push(
            {
                '$type': 'object-list',
                '$format': format,
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
