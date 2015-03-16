var command = document.argv[1];
var xmlhttp = new XMLHttpRequest();

switch(command) {
case "list":
    // unimplemented callbacks
    xmlhttp.open("GET", "/dnc", false);
    xmlhttp.send();
    var records = eval('(' + xmlhttp.responseText + ')');
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
        document.argv[0]": Unknown command '" + command + "'"
    ];
}
