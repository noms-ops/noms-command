var nomsargs = { };

(function (self) {
    function kwargs() {
        var result = { };
        for (i = 0; i < arguments.length; i++) {
            pair = arguments[i].split("=", 2);
            result[pair[0]] = pair[1];
        }
        return result;
    }

})(nomsargs);
