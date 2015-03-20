var nomsargs = { };

(function (self) {

    function NomsArgs(args, opt) {
        var comparisons = [ ];
        var assignment = { };
        var warnings = [ ];
        var errors = [ ];
        var extra = [ ];

        args.map(function (item) {
            var match = /^([^!=~><]+)(==|=|!=|>=|<=|~|!~)(.*)$/.exec(item)
            if (match == null) {
                extra.push(item);
            } else {
                var m_field = match[1];
                var m_op = match[2];
                var m_rvalue = match[3];

                comparisons.push({
                    field: m_field,
                    op: m_op,
                    rvalue: m_rvalue
                });

                if (m_op == '=') {
                    assignment[m_field] = m_rvalue
                }
            }
        });

        this.comparisons = comparisons;
        this.assignment = assignment;
        this.warnings = warnings;
        this.errors = errors;
        this.extra = extra;
    };

    NomsArgs.prototype = {
        keys: function () {
            this.comparisons.map(function (comp) { return comp.field; });
        },
        assignmentKeys: function () {
            var keys = [ ];

            for (var key in this.assignment) {
                if (this.assignment.hasOwnProperty(key)) {
                    keys.push(key);
                }
            }

            return keys;
        },
        query: function () {
            return encodeURI(this.comparisons.map(function (comp) {
                return comp.field + comp.op + comp.rvalue;
            }).join('&'));
        },
        assignmentQuery: function () {
            return encodeURI(this.assignmentKeys().map(function (key) {
                return key + '=' + this.assignment[key];
            }).join('&'))
        },
        keys: function () {
            return this.comparisons.map(function (comp) { comp.field });
        }
    };

    self.NomsArgs = NomsArgs;

})(nomsargs);
