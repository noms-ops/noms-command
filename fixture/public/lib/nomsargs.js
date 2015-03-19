var nomsargs = { };

(function (self) {

    function NomsArgs(args) {
        var comparisons = [ ];
        var simple = [ ];
        var extra = [ ];

        args.map(function (item) {
            var match = /^([^!=~><]+)(==|=|!=|>=|<=|~|!~)(.*)$/.exec(item)
            if (match == null) {
                extra.push(item);
            } else {
                comparisons.push({
                    field: match[1],
                    op: match[2],
                    rvalue: match[3]
                });

                if (match[1] == '=' || match[1] == '==') {
                    simple.push(item);
                }
            }
        });

        this.comparisons = comparisons;
        this.simple = simple;
        this.extra = extra;
    };

    NomsArgs.prototype = {
        query: function() {
            return encodeURI(this.comparisons.map(function (comp) {
                return comp.field + comp.op + comp.rvalue;
            }).join('&'));
        },
        keys: function() {
            return this.comparisons.map(function (comp) { comp.field });
        }
    };

    self.NomsArgs = NomsArgs;

})(nomsargs);
