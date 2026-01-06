
/**********************
/* Parking B - MuseScore - Solo Analyser core plugin
/* v1.2.1
/* ChangeLog:
/* 	- 1.0.0: Initial release
/* 	- 1.0.1: Improved robustness in CompareObjects
/* 	- 1.1.0: New don't dig into list that applies in include mode
/* 	- 1.1.1: Les objets sans clés sont correctement affichés
/* 	- 1.1.2: Don't dig into objects when we are already at the maxlevl
/* 	- 1.1.3: Conflicts between include list and dontdig list
/* 	- 1.2.0: new startAtProperty option
/* 	- 1.2.0: new startAtParent option
/* 	- 1.2.1: error in check of property names vs. the filterList when RegExp were present in the list
/**********************************************/
var default_nodiglist = ["bbox", /^pos/, "/color/", "/align/", "next", "prev", "nextInMeasure", "prevInMeasure", "lastMeasure", "firstMeasure", "lastMeasureMM", "firstMeasureMM", "prevMeasure", "nextMeasure", "prevMeasureMM", "nextMeasureMM", "lastTiedNote", "firstTiedNote"];
var default_filterList = ["elements", "staff", "page"].concat(default_nodiglist);
var minimum_set = ["type", "name", "segmentType"];
var deepest_parent = 70; //Element.MEASURE;
var deepest_level = 1;

var xloggers = [];

var stopMe = false;

function forceStop() {
    stopMe=true;
}

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
function debugNonNulls(prefix, element, how) {
    if (typeof how === 'undefined') {
        how = {};
    }

    if (typeof how.limitToNotNull !== 'boolean') {
        how.limitToNotNull = true;
    }

   
    stopMe=false;
    start(prefix, element, how);

}
/**
* One can use maxlevel=-1 as maxlevel=0 to have a simplified output presentation
*/
function debugAll(prefix, element, how, level, sub) {
    stopMe=false;
    start(prefix, element, how, level, sub);
}

/**
* One can use maxlevel=-1 as maxlevel=0 to have a simplified output presentation
* @deprecated: Use #debugAll
*/
function start(prefix, element, how, level, sub) {

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
    if (typeof(how.startat) !== 'number')
        how.startat = undefined; // starting from current element
    if (typeof(how.dontdig) === 'undefined')
        how.dontdig = default_nodiglist;
    if (typeof how.limitToNotNull !== 'boolean')
        how.limitToNotNull = false;

    // cleaning of the filterList (i.e. building of the regular expression)
    for(var i=0;i<how.filterList.length;i++) {
        var obj=how.filterList[i];
        if (typeof obj==="string" && Array.from(obj)[0]==='/') {
            try {
                var re=obj.split("/")[1];
                how.filterList[i]=new RegExp(re,'i');
            } catch (e) {
                console.warn("fail to build RegExp for \""+obj+"\"");
            }
        }
    }
    // managing conflicts between included list and dontdig list
    if (how.isinclude) {
        how.dontdig=how.dontdig.filter(function(e) { return how.filterList.indexOf(e)===-1});
    }
    
    debugO(prefix, element, how, level, sub);
}

function debugO(prefix, element, how, level, sub) {

    var title = "";

    if(stopMe) {
         addlog("!! Forced Stop [1]");
         return;
    }


    // -- titles --------------------------------------------------------
    if (level === 0 && sub === 0) {
        title = prefix;
        if (title && how.maxlevel >= 0)
            addlog("=== " + title + " (start) ===");
    }

    if (level === 0 && how.maxlevel >= 0) {
        prefix = "";
        for (var i = 0; i < sub; i++) {
            prefix += "..";
        }
        addlog(prefix + "Properties: ");
        prefix += "..[" + element.userName() + "]";
    }

    var label = prefix; // + "(" + level + ")";

    // -- starting point --------------------------------------------------------
    var _how=  JSON.parse(JSON.stringify(how)) ;  // cloning "how"
    _how.filterList=how.filterList; // je garder la liste d'origine (avec des RegExp) car le clonage perd la nature de l'objet
    if (how.startAtProperty) {
        var what = how.startAtProperty;
        var startingPoint;

        try {
            startingPoint = eval("element" + ((what.charAt(0) !== '.') ? "." : "") + what);
        } catch (error) {
            console.error("Failed to parse the startAtProperty expression : "+error);
        }

        if (startingPoint) {
            element = startingPoint;
            _how.startAtProperty = undefined;
        }
    }

    if (how.startat) {
        if (element.type === how.startat) {
            _how.startat=undefined;
        } else {
            addlog("Bypassing: " + element.userName() + " (check next parent)");
        }
    }

    // -- analyze --------------------------------------------------------
    if (typeof _how.startat === 'undefined') { // si on a un "startat" toujouts présent, c'est qu'on n'a pas encore atteint le bon parent
    if (typeof element === 'undefined') {
            if (!_how.limitToNotNull && !_how.startAtProperty) // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
            addlog(label + ": undefined");
    } else if (element === null) {
            if (!_how.limitToNotNull && !_how.startAtProperty) // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
            addlog(label + ": null");
    } else if (Array.isArray(element)) { // QMLLists are not arrays but behave like arrays
        for (var i = 0; i < element.length; i++) {
            debugO(prefix + "-" + i, element[i], _how, level);
        }
    } else if (typeof element === 'object') {
        if (level <= _how.maxlevel) {
            var kys = Object.keys(element);


                if ((kys.length === 0)  && !_how.startAtProperty) { // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
                if (typeof(element.userName) === 'function') {
                    addlog(label + ": " + element.userName());
                } else {
                    // addlog(label + ": " + element.toString());
                    addlog(label + ": " + element);
                }
            }

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
                    
                    if(stopMe) {
                         addlog("!! Forced Stop [2]");
                         return;
                    }
                    
                var key = kys[i];
                var value = element[key];
                var asint = parseInt(key);

				// console.log("--- "+key+" ---");
                
                var DEBUG="false";

                // identifying if a key must be further analyzed
                var keep = false;

                // ..we always keep the "type" (etc) properties
                if (minimum_set.indexOf(key) > -1) {
                    keep = true;
					// console.log("keep because in minimum set");
                }

                // ..in "include" mode we never keep what's in the "don't dig into" list
                else if (_how.dontdig.indexOf(key) > -1 && _how.isinclude) {
                    keep = false;
					// console.log("reject because in `don't dig` list");
                }

                // ..we never keep the parent and the elements of the 1st level if a separated analyse is required
                else if ((key === 'parent' || key === 'elements') && level === 0 && _how.separateParent) {
                    keep = false;
                        // console.log("reject because is 'parent'");
                }
                // ..check d'une pseudo array
                else if ((asint == key) && (asint < element.length)) { // "==" on purpose instead of "==="
                    keep = true;
					// console.log("keep because is an array item");
                }

                // ..in "include" mode, we keep every value which is an object in order to seek for matching properties underneath, if we are not at the max level
                else if ((typeof value === 'object') && _how.isinclude && (level < _how.maxlevel)) {
                    keep = true;
					// console.log("keep because is an object, and we are going to investigate all objects");
                }

                // ..we exclude/include _how's in the filter list
                else {
                    var res=check(key, _how.filterList);
                    keep = (res != !_how.isinclude);
					// console.log((keep?"keep":"reject")+" because in include/exclude list");
                }
				
				// console.log("--- "+key+" --- decision: "+keep);

                // digging into the keys needing further analyze
                if (keep) {
                    debugO(prefix + "." + key, value, _how, level + 1);
                    } else if (!_how.hideExcluded && !_how.startAtProperty) { // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
                    addlog(label + "." + key + ": ---"); // in "include" mode, hide how's excluded.
                }
            }

        }
        // Max level: just logging basic information
        else if (level == (_how.maxlevel + 1)) {
            for (var i = 0; i < minimum_set.length; i++) {

                    if(stopMe) {
                         addlog("!! Forced Stop [3]");
                         return;
                    }
                    
                var d = minimum_set[i];
                if (typeof(element[d]) !== 'undefined') {
                    debugO(prefix + "." + d, element[d], _how, level + 1);
                }
            }

            var more;
            var kys = Object.keys(element);
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
                if (!_how.startAtProperty) // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
                addlog(label + "." + more);
        }
        // Beyong the maxlevel, simply logging a string summary of the object
        else if (typeof(element.userName) === 'function') {
                if (!_how.startAtProperty) // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
                addlog(label + ": " + element.userName());
        } else { // shouldn't not occur
                if (!_how.startAtProperty) // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
                addlog(label + ": " + element.toString());
        }
        }
    else {
            if (!_how.startAtProperty) // si on a un "startAtProperty" toujouts présent, c'est qu'on n'est pas encore au bon endroit
            addlog(label + ": " + element.toString());
    }
    if (level === 0) {
        //addlog("~~ "+title+": end of analyze ~~");
    }

    // analyze  des elements
    if ((level === 0) &&
        element &&
        (typeof(element.elements) !== 'undefined') &&
        (_how.separateParent) &&
        //            (element.elements.length>0) &&
        (!check("elements", _how.filterList) || _how.isinclude)) {
        addlog("");
        addlog("Elements: (count="+element.elements.length+")");
        for (var i = 0; i < element.elements.length; i++) {
            addlog("..Element: " + element.elements[i].userName());
            var howElement=JSON.parse(JSON.stringify(how)); // cloning the original "how" 
            howElement.separateParent=false;
            howElement.stopat=element.type;
            debugO("", element.elements[i], howElement, 0, sub + 2); // restart at level 0
        }
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
        (how.separateParent) &&
        (!check("parent", how.filterList) || how.isinclude)) {

        addlog("");

        if ((typeof(element.parent) === 'undefined') ||
            (element.parent === null)) {
            addlog("Parent: no more parents");

        } else if (element.type === how.stopat) {
            addlog("Parent: " + element.parent.userName() + " (stopping here)");

        } else if (element.type === element.parent.type) {
            addlog("Parent: " + element.parent.userName() + " (stopping here, because it seems we are looping!)");

        } else {
            addlog("Parent: " + element.parent.userName());
            debugO("", element.parent, how, 0, 1) // restart at level 0
        }
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
    var dd = (e.search(/posAbove/i) >= 0); //DEBUG
    for (var t = 0; t < tests.length; t++) {
        // Les éléments de la liste sont soit des Strings soit des Regexp

        var obj = tests[t];

        if (dd)
            console.log("Comparing " + e + " vs. " + obj.toString())


        var typof = typeof obj;
        // Essayer de détecter les regular expressions dans la liste
        if (obj instanceof RegExp) typof="regexp";
        if (Object.prototype.toString.call(obj) === '[object RegExp]') typof = "regexp";
        if (obj[Symbol.test] !== undefined) typof = "regexp";
        if (typeof obj.test === 'function' && typeof obj.source === 'string') typof="regexp";
        
        
        //console.log(typof);
        if (typof === "string") {
            if (dd)
                console.log("..As String")
            if (e.search(obj) >= 0) {
                if (dd)
                    console.log("Found");
                return true;
            }
        } else if (typof === "regexp") {
            if (dd)
                console.log("..As Regexp")
            if (obj.test(e)) { // obj.test(xxx) 
                if (dd)
                    console.log("Found");
                return true;
            }
        } else {
            if (dd)
                console.log("--unknown => bypassed")
        }
        
        if (dd)
            console.log("Not Found");

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