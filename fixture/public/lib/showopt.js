var optspec = [
    ["-n", "--dry-run", "Don't change anything"],
    ["-d", "--debug", "Enable debugging output"],
    ["-c", "--config FILE", "Specify configuration file"]
];

var parser = new optparse.OptionParser(optspec);
var options = { "dry-run": false,
                "debug": false,
                "config": null }

parser.on("dry-run", function () { options["dry-run"] = true })
parser.on("debug", function() { options["debug"] = true })
parser.on("config", function(opt, file) { options["config"] = file })

parser.parse(document.argv)

document.body = options
