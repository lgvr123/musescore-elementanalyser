
/**********************
/* Parking B - MuseScore - Solo Analyser core plugin
/* v1.0.0
/* ChangeLog:
/* 	- 1.0.0: Initial release
/* 	- 1.0.1: Improved robustness in CompareObjects
/* 	- 1.0.1: New don't dig into list that applies in include mode
/**********************************************/
var default_nodiglist = ["bbox", /pos/i, /color/i, /align/i, "next", "prev", "nextInMeasure", "prevInMeasure", "lastMeasure", "firstMeasure", "lastMeasureMM", "firstMeasureMM", "prevMeasure", "nextMeasure", "prevMeasureMM", "nextMeasureMM","lastTiedNote","firstTiedNote"];
var default_filterList = ["elements", "staff", "page"].concat(default_nodiglist);
var minimum_set = ["type", "name", "segmentType"];
var deepest_parent = 90; //Element.SEGMENT;
var deepest_level = 1;

var xloggers = [];

function addLogger(f) {
    if (typeof f !== 'function') {
        console.warn("Invalid logger function : " + ((f) ? f.toString() : "undefined/null"));
        return;
    }
    if (!xloggers)
        xloggers = [];
    xloggers.push(f);
}

// -- core methods ---------------------------------------------

function debugO(prefix, element, how, level, sub) {
	
    var title = "";

    if (typeof level === 'undefined') {
        level = 0;
    }

    if (typeof sub === 'undefined') {
        sub = 0;
    }
    // -- analyze context --------------------------------------------------------
    if (Array.isArray(how)) {
        how = {
            filterList: how
        };
    } else if (typeof how === 'string') {
        how = {
            filterList: [how]
        };
    } else if ((typeof how === 'undefined') || (typeof how !== 'object')) {
        how = {};
    }

    if (typeof(how.filterList) === 'undefined')
        how.filterList = default_filterList;
    if (typeof(how.hideExcluded) !== 'boolean')
        how.hideExcluded = false;
    if (typeof(how.isinclude) !== 'boolean')
        how.isinclude = false;
    if (typeof(how.maxlevel) !== 'number')
        how.maxlevel = deepest_level;
    if (typeof(how.separateParent) !== 'boolean')
        how.separateParent = true;
    if (typeof(how.stopat) !== 'number')
        how.stopat = deepest_parent;
    if (typeof(how.dontdig) === 'undefined')
        how.dontdig = default_nodiglist;

    // -- titles --------------------------------------------------------
    if (level === 0 && sub === 0) {
        title = prefix;
        if (title && how.maxlevel > 0)
            addlog("=== " + title + " (start) ===");
    }

    if (level === 0 && how.maxlevel > 0) {
        prefix = "";
        for (var i = 0; i < sub; i++) {
            prefix += "..";
        }
        addlog(prefix + "Properties: ");
        prefix += "..";
    }

    var label = prefix; // + "(" + level + ")";


    // -- analyze --------------------------------------------------------
    if (typeof element === 'undefined') {
        addlog(label + ": undefined");
    } else if (element === null) {
        addlog(label + ": null");
    } else if (Array.isArray(element)) { // QMLLists are not arrays but behave like arrays
        for (var i = 0; i < element.length; i++) {
            debugO(prefix + "-" + i, element[i], how, level);
        }
    } else if (typeof element === 'object') {
        if (level <= how.maxlevel) {
            var kys = Object.keys(element);

            // ordering of the keys for easisest analyse
            kys = kys.sort(function (a, b) {
                var ia = minimum_set.indexOf(a);
                var ib = minimum_set.indexOf(b);
                if (ia == -1) {
                    if (ib == -1) {
                        return a.localeCompare(b);
                    } else {
                        return 1;
                    }
                } else { // ia>=0
                    if (ib == -1) {
                        return -1;
                    } else {
                        return ia - ib;
                    }
                }

            });

            // looping thru the keys
            for (var i = 0; i < kys.length; i++) {
                var key = kys[i];
                var value = element[key];
                var asint = parseInt(key);

                // identifying if a key must be further analyzed
                var keep = false;

                // ..we always keep the "type" (etc) properties
                if (minimum_set.indexOf(key) > -1) {
                    keep = true;
                }
                
                // ..in "include" mode we never keep what's in the "don't dig into" list
				else if (how.dontdig.indexOf(key) > -1 && how.isinclude) {
                    keep = false;
                }

                // ..we never keep the parent and the elements of the 1st level if a separated analyse is required
                else if ((key === 'parent' || key === 'elements') && level === 0 && how.separateParent) {
                    keep = false;

                }
                // ..check d'une pseudo array
                else if ((asint == key) && (asint < element.length)) { // "==" on purpose instead of "==="
                    keep = true;
                }

                // ..in "include" mode, we keep every value which is an object in order to seek for matching properties underneath.
                else if ((typeof value === 'object') && how.isinclude) {
                    keep = true;
                }

                // ..we exclude/include how's in the filter list
                else {
                    keep = (check(key, how.filterList) ^ !how.isinclude);
                }

                // digging into the keys needing further analyze
                if (keep) {
                    debugO(prefix + "." + key, value, how, level + 1);
                } else if (!how.isinclude || !how.hideExcluded) {
                    addlog(label + "." + key + ": ---"); // in "include" mode, hide how's excluded.
                }
            }

        }
        // Max level: just logging basic information
        else if (level == (how.maxlevel + 1)) {
            for (var i = 0; i < minimum_set.length; i++) {
                var d = minimum_set[i];
                if (typeof(element[d]) !== 'undefined') {
                    debugO(prefix + "." + d, element[d], how, level + 1);
                }
            }

            var more;
            var kys = Object.keys(element)
                if (kys.length > 0) {
                    var max = 8;
                    var more = kys.filter(function (e) {
                        return minimum_set.indexOf(e) === -1
                    });
                    if (more.length < max) {
                        more = more.join(", ");
                    } else {
                        more = more.filter(function (e, pos) {
                            return pos < max
                        });
                        more = more.join(", ") + ", ...";
                    }
                } else if (typeof(element.userName) === 'function') {
                    more = element.userName();
                } else
                    more = element.toString();
                addlog(label + "." + more);
        }
        // Beyong the maxlevel, simply logging a string summary of the object
        else if (typeof(element.userName) === 'function') {
            addlog(label + ": " + element.userName());
        } else { // shouldn't not occur
            addlog(label + ": " + element.toString());
        }
    } else {
        addlog(label + ": " + element);
    }

    if (level === 0) {
        //addlog("~~ "+title+": end of analyze ~~");
    }

    // analyze  des elements
    if ((level === 0) &&
        element &&
        (typeof(element.elements) !== 'undefined') &&
        (how.separateParent) &&
        //            (element.elements.length>0) &&
        (!check("elements", how.filterList) || how.isinclude)) {
        addlog("");
        addlog("Elements:");
        for (var i = 0; i < element.elements.length; i++) {
            addLog("..Element: " + element.elements[i].userName());
            debugO("", element.elements[i], how, 0, sub + 2); // restart at level 0
        }
    }

    // if (level === 0) {
        // console.log("parent: " + (element.parent ? element.parent.toString() : "/"));
        // console.log("separateParent: " + how.separateParent);
        // console.log("type: " + element.type);
    // }

    // analyze  du parent
    if ((level === 0) &&
        element &&
        (typeof(element.parent) !== 'undefined') &&
        (how.separateParent) &&
        (!check("parent", how.filterList) || how.isinclude) &&
        (element.type !== how.stopat)) {
        addlog("");
        addlog("Parent: " + element.parent.userName());
        debugO("", element.parent, how, 0, 1) // restart at level 0
    }

    if (level === 0 && sub === 0) {
        if (title && how.maxlevel > 0)
            addlog("=== " + title + " (end) ===");
    }

}

function compareObjects(objects, properties, how) {
    if (typeof how === 'undefined') {
        how = {
            maxlevel: 0,
        };
    }

    for (var e = 0; e < properties.length; e++) {
        for (var s = 0; s < objects.length; s++) {
            var score = objects[s];
            var prop = properties[e];
            var action = "score." + prop;
            var result = "n/a";
            if (typeof score === 'undefined')
                result = "invalid object (undefined)";
            else if (score === null)
                result = "invalid object (null)";
            else

                try {
                    result = eval(action);
                } catch (error) {
                    result = error;
                }

            debugO("[" + s + "] - " + prop, result, how);
        }
    }
}

// -- working methods ---------------------------------------------

function check(e, tests) {
    for (var t = 0; t < tests.length; t++) {
        if ((tests[t].test && tests[t].test(e)) || (tests[t] === e))
            return true;
    }
    return false;
}

function addlog(text) {
    console.log(text);
    if (xloggers) {
        for (var i = 0; i < xloggers.length; i++) {
            var logger = xloggers[i];
            logger(text);
        }
    }
}
