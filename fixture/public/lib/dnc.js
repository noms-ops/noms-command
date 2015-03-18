if (document.argv.length > 1) {
    var argv = document.argv;
    var me = argv.shift();
    var command;
    var format;
    var xmlhttp = new XMLHttpRequest();

    // document attributes can be set
    // but are immutable
    document.body = [ ];
    var output = [ ];

    var optspec = [
        ["-J", "--json", "Display JSON"],
        ["-Y", "--yaml", "Display YAML"],
        ["-C", "--csv", "Display CSV"],
        ["-v", "--verbose", "Enable verbose output"],
        ["--nofeedback", "Don't print feedback"]
    ];

    var parser = new optparse.OptionParser(optspec);
    var options = {
        "feedback": true,
        "format": "default",
        "verbose": false
    };
    var args = [ ];

    parser.on("verbose", function() { options["verbose"] = true });
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
    parser.on(0, function(arg) { command = arg });
    parser.on(function(arg) { args.push(arg); });

    parser.parse(argv);

    switch(command) {
    case "list":
        if (options["format"] === "default") {
            format = "lines";
        } else {
            format = options["format"];
        }
        xmlhttp.open("GET", "/dnc", false);
        xmlhttp.send();
        var records = eval('(' + xmlhttp.responseText + ')');
        output.push(
            {
                '$type': 'object-list',
                '$format': format,
                '$columns': [
                    { 'field': 'id', 'width': 3, 'align': 'right' },
                    { 'field': 'name', 'width': 20 },
                    { 'field': 'phone', 'width': 20 }
                ],
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
