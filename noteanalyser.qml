import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import FileIO 3.0

MuseScore {
    menuPath: "Plugins.Note analyser"
    description: "Retrieve all the properties about the selected chors and notes"
    version: "1.0.0"
    pluginType: "dialog"
    requiresScore: true
    width: 600
    height: 600

    /** the notes to which the fingering must be made. */
    property var __notes: [];

    // config


    readonly property var default_excludes: ["parent", "elements", "staff", "page"]
    readonly property var minimum_set: ["type", "name"]
    readonly property var deepest_parent: Element.SEGMENT
    readonly property var deepest_level: 1

    // -----------------------------------------------------------------------
    // --- Read the score ----------------------------------------------------
    // -----------------------------------------------------------------------
    onRun: {
        // analysing whatever is selected
        var selection = curScore.selection;

        var el = selection.elements;
        if (el.length == 0) {
            invalidSelectionDialog.open();
            return;
        }

        var timer = new Date();

        console.time("analyze");

        for (var i = 0; i < el.length; i++) {
            var note = el[i];
            addlog("analysing the selected element " + (i + 1) + " (" + note.name + " [" + note.type + "]" + ")");
            //if (note.type!=84) continue;
            logElement(note);
            addlog("\n");
        }

        console.log("my own elapsed = " + (new Date() - timer));
    }

    // -----------------------------------------------------------------------
    // --- Score manipulation ------------------------------------------------
    // -----------------------------------------------------------------------


    function enrichNote(note) {
        // accidental
        var id = note.accidentalType;
        note.accidentalName = "UNKOWN";
        for (var i = 0; i < accidentals.length; i++) {
            var acc = accidentals[i];
            if (id == eval("Accidental." + acc.name)) {
                note.accidentalName = acc.name;
                break;
            }
        }

        // note name and octave
        var tpc = {
            'tpc': 0,
            'name': '?',
            'raw': '?'
        };
        var pitch = note.pitch;
        var pitchnote = pitchnotes[pitch % 12];
        var noteOctave = Math.floor(pitch / 12) - 1;

        for (var i = 0; i < tpcs.length; i++) {
            var t = tpcs[i];
            if (note.tpc == t.tpc) {
                tpc = t;
                break;
            }
        }

        if (pitchnote == "B" && tpc.raw == "C") {
            noteOctave++;
        } else if (pitchnote == "C" && tpc.raw == "B") {
            noteOctave--;
        }

        note.extname = {
            "fullname": tpc.name + noteOctave,
            "name": tpc.raw + noteOctave,
            "raw": tpc.raw,
            "octave": noteOctave
        };
        return;

    }

    /**
     * Verify if "what" is enterily contained in "within"
     */
    function find(what, within) {
        var t,
        t2;
        //    if (b.length > a.length)
        //        t = b, b = a, a = t; // indexOf to loop over shorter
        // Je ne garde que ceux qui sont en commun dans les 2 arrays
        t = what.filter(function (e) {
            return within.indexOf(e) >  - 1;
        });
        // Je supprime de la chaîne à retrouver ce qu'il ya dans l'interection
        // Il ne devrait rien manquer, donc le résultat devrait être vide.
        t2 = what.filter(function (e) {
            return t.indexOf(e) ===  - 1;
        });
        return (t2.length === 0);
    }

    function doesIntersect(array1, array2) {
        var intersect = array1.filter(function (n) {
            return array2.indexOf(n) !== -1;
        });
        return intersect.length > 0;
    }

    // -----------------------------------------------------------------------
    // --- Screen design -----------------------------------------------------
    // -----------------------------------------------------------------------
    ColumnLayout {
        id: panMain

        anchors.fill: parent
        spacing: 5
        anchors.topMargin: 10
        anchors.rightMargin: 10
        anchors.leftMargin: 10
        anchors.bottomMargin: 5

        ScrollView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            TextArea {
                id: txtLog
                text: ""
                placeholderText: "here will come the selected note details..."
                background: Rectangle {
                    color: "white"
                    border.color: "#C0C0C0"
                }
            }
        }

        Item { // buttons row // DEBUG was Item
            Layout.fillWidth: true
            Layout.preferredHeight: buttonBox.implicitHeight

            RowLayout {
                id: panButtons
                anchors.fill: parent
                Item { // spacer // DEBUG Item/Rectangle
                    id: spacer
                    implicitHeight: 10
                    Layout.fillWidth: true
                }

                Button {
                    id: buttonBox
                    text: "Close"

                    onClicked: Qt.quit()
                }
            }
        } // button rows

    }
    // ----------------------------------------------------------------------
    // --- Screen support ---------------------------------------------------
    // ----------------------------------------------------------------------
    MessageDialog {
        id: invalidSelectionDialog
        icon: StandardIcon.Warning
        standardButtons: StandardButton.Ok
        title: 'Invalid Selection!'
        text: 'The selection is not valid'
        detailedText: 'At least one note must be selected, and all the notes must of the same instrument.'
        onAccepted: {
            Qt.quit()
        }
    }

    // -----------------------------------------------------------------------
    // --- Accidentals -------------------------------------------------------
    // -----------------------------------------------------------------------

    readonly property var pitchnotes: ['C', 'C', 'D', 'D', 'E', 'F', 'F', 'G', 'G', 'A', 'A', 'B']

    readonly property var tpcs: [{
            'tpc': -1,
            'name': 'F♭♭',
            'raw': 'F'
        }, {
            'tpc': 0,
            'name': 'C♭♭',
            'raw': 'C'
        }, {
            'tpc': 1,
            'name': 'G♭♭',
            'raw': 'G'
        }, {
            'tpc': 2,
            'name': 'D♭♭',
            'raw': 'D'
        }, {
            'tpc': 3,
            'name': 'A♭♭',
            'raw': 'A'
        }, {
            'tpc': 4,
            'name': 'E♭♭',
            'raw': 'E'
        }, {
            'tpc': 5,
            'name': 'B♭♭',
            'raw': 'B'
        }, {
            'tpc': 6,
            'name': 'F♭',
            'raw': 'F'
        }, {
            'tpc': 7,
            'name': 'C♭',
            'raw': 'C'
        }, {
            'tpc': 8,
            'name': 'G♭',
            'raw': 'G'
        }, {
            'tpc': 9,
            'name': 'D♭',
            'raw': 'D'
        }, {
            'tpc': 10,
            'name': 'A♭',
            'raw': 'A'
        }, {
            'tpc': 11,
            'name': 'E♭',
            'raw': 'E'
        }, {
            'tpc': 12,
            'name': 'B♭',
            'raw': 'B'
        }, {
            'tpc': 13,
            'name': 'F',
            'raw': 'F'
        }, {
            'tpc': 14,
            'name': 'C',
            'raw': 'C'
        }, {
            'tpc': 15,
            'name': 'G',
            'raw': 'G'
        }, {
            'tpc': 16,
            'name': 'D',
            'raw': 'D'
        }, {
            'tpc': 17,
            'name': 'A',
            'raw': 'A'
        }, {
            'tpc': 18,
            'name': 'E',
            'raw': 'E'
        }, {
            'tpc': 19,
            'name': 'B',
            'raw': 'B'
        }, {
            'tpc': 20,
            'name': 'F♯',
            'raw': 'F'
        }, {
            'tpc': 21,
            'name': 'C♯',
            'raw': 'C'
        }, {
            'tpc': 22,
            'name': 'G♯',
            'raw': 'G'
        }, {
            'tpc': 23,
            'name': 'D♯',
            'raw': 'D'
        }, {
            'tpc': 24,
            'name': 'A♯',
            'raw': 'A'
        }, {
            'tpc': 25,
            'name': 'E♯',
            'raw': 'E'
        }, {
            'tpc': 26,
            'name': 'B♯',
            'raw': 'B'
        }, {
            'tpc': 27,
            'name': 'F♯♯',
            'raw': 'F'
        }, {
            'tpc': 28,
            'name': 'C♯♯',
            'raw': 'C'
        }, {
            'tpc': 29,
            'name': 'G♯♯',
            'raw': 'G'
        }, {
            'tpc': 30,
            'name': 'D♯♯',
            'raw': 'D'
        }, {
            'tpc': 31,
            'name': 'A♯♯',
            'raw': 'A'
        }, {
            'tpc': 32,
            'name': 'E♯♯',
            'raw': 'E'
        }, {
            'tpc': 33,
            'name': 'B♯♯',
            'raw': 'B'
        }
    ]

    readonly property var accidentals: [{
            'name': 'NONE',
            'image': 'NONE.png'
        }, {
            'name': 'FLAT',
            'image': 'FLAT.png'
        }, {
            'name': 'NATURAL',
            'image': 'NATURAL.png'
        }, {
            'name': 'SHARP',
            'image': 'SHARP.png'
        }, {
            'name': 'SHARP2',
            'image': 'SHARP2.png'
        }, {
            'name': 'FLAT2',
            'image': 'FLAT2.png'
        }, {
            'name': 'NATURAL_FLAT',
            'image': 'NATURAL_FLAT.png'
        }, {
            'name': 'NATURAL_SHARP',
            'image': 'NATURAL_SHARP.png'
        }, {
            'name': 'SHARP_SHARP',
            'image': 'SHARP_SHARP.png'
        }, {
            'name': 'FLAT_ARROW_UP',
            'image': 'FLAT_ARROW_UP.png'
        }, {
            'name': 'FLAT_ARROW_DOWN',
            'image': 'FLAT_ARROW_DOWN.png'
        }, {
            'name': 'NATURAL_ARROW_UP',
            'image': 'NATURAL_ARROW_UP.png'
        }, {
            'name': 'NATURAL_ARROW_DOWN',
            'image': 'NATURAL_ARROW_DOWN.png'
        }, {
            'name': 'SHARP_ARROW_UP',
            'image': 'SHARP_ARROW_UP.png'
        }, {
            'name': 'SHARP_ARROW_DOWN',
            'image': 'SHARP_ARROW_DOWN.png'
        }, {
            'name': 'SHARP2_ARROW_UP',
            'image': 'SHARP2_ARROW_UP.png'
        }, {
            'name': 'SHARP2_ARROW_DOWN',
            'image': 'SHARP2_ARROW_DOWN.png'
        }, {
            'name': 'FLAT2_ARROW_UP',
            'image': 'FLAT2_ARROW_UP.png'
        }, {
            'name': 'FLAT2_ARROW_DOWN',
            'image': 'FLAT2_ARROW_DOWN.png'
        }, {
            'name': 'MIRRORED_FLAT',
            'image': 'MIRRORED_FLAT.png'
        }, {
            'name': 'MIRRORED_FLAT2',
            'image': 'MIRRORED_FLAT2.png'
        }, {
            'name': 'SHARP_SLASH',
            'image': 'SHARP_SLASH.png'
        }, {
            'name': 'SHARP_SLASH4',
            'image': 'SHARP_SLASH4.png'
        }, {
            'name': 'FLAT_SLASH2',
            'image': 'FLAT_SLASH2.png'
        }, {
            'name': 'FLAT_SLASH',
            'image': 'FLAT_SLASH.png'
        }, {
            'name': 'SHARP_SLASH3',
            'image': 'SHARP_SLASH3.png'
        }, {
            'name': 'SHARP_SLASH2',
            'image': 'SHARP_SLASH2.png'
        }, {
            'name': 'DOUBLE_FLAT_ONE_ARROW_DOWN',
            'image': 'DOUBLE_FLAT_ONE_ARROW_DOWN.png'
        }, {
            'name': 'FLAT_ONE_ARROW_DOWN',
            'image': 'FLAT_ONE_ARROW_DOWN.png'
        }, {
            'name': 'NATURAL_ONE_ARROW_DOWN',
            'image': 'NATURAL_ONE_ARROW_DOWN.png'
        }, {
            'name': 'SHARP_ONE_ARROW_DOWN',
            'image': 'SHARP_ONE_ARROW_DOWN.png'
        }, {
            'name': 'DOUBLE_SHARP_ONE_ARROW_DOWN',
            'image': 'DOUBLE_SHARP_ONE_ARROW_DOWN.png'
        }, {
            'name': 'DOUBLE_FLAT_ONE_ARROW_UP',
            'image': 'DOUBLE_FLAT_ONE_ARROW_UP.png'
        }, {
            'name': 'FLAT_ONE_ARROW_UP',
            'image': 'FLAT_ONE_ARROW_UP.png'
        }, {
            'name': 'NATURAL_ONE_ARROW_UP',
            'image': 'NATURAL_ONE_ARROW_UP.png'
        }, {
            'name': 'SHARP_ONE_ARROW_UP',
            'image': 'SHARP_ONE_ARROW_UP.png'
        }, {
            'name': 'DOUBLE_SHARP_ONE_ARROW_UP',
            'image': 'DOUBLE_SHARP_ONE_ARROW_UP.png'
        }, {
            'name': 'DOUBLE_FLAT_TWO_ARROWS_DOWN',
            'image': 'DOUBLE_FLAT_TWO_ARROWS_DOWN.png'
        }, {
            'name': 'FLAT_TWO_ARROWS_DOWN',
            'image': 'FLAT_TWO_ARROWS_DOWN.png'
        }, {
            'name': 'NATURAL_TWO_ARROWS_DOWN',
            'image': 'NATURAL_TWO_ARROWS_DOWN.png'
        }, {
            'name': 'SHARP_TWO_ARROWS_DOWN',
            'image': 'SHARP_TWO_ARROWS_DOWN.png'
        }, {
            'name': 'DOUBLE_SHARP_TWO_ARROWS_DOWN',
            'image': 'DOUBLE_SHARP_TWO_ARROWS_DOWN.png'
        }, {
            'name': 'DOUBLE_FLAT_TWO_ARROWS_UP',
            'image': 'DOUBLE_FLAT_TWO_ARROWS_UP.png'
        }, {
            'name': 'FLAT_TWO_ARROWS_UP',
            'image': 'FLAT_TWO_ARROWS_UP.png'
        }, {
            'name': 'NATURAL_TWO_ARROWS_UP',
            'image': 'NATURAL_TWO_ARROWS_UP.png'
        }, {
            'name': 'SHARP_TWO_ARROWS_UP',
            'image': 'SHARP_TWO_ARROWS_UP.png'
        }, {
            'name': 'DOUBLE_SHARP_TWO_ARROWS_UP',
            'image': 'DOUBLE_SHARP_TWO_ARROWS_UP.png'
        }, {
            'name': 'DOUBLE_FLAT_THREE_ARROWS_DOWN',
            'image': 'DOUBLE_FLAT_THREE_ARROWS_DOWN.png'
        }, {
            'name': 'FLAT_THREE_ARROWS_DOWN',
            'image': 'FLAT_THREE_ARROWS_DOWN.png'
        }, {
            'name': 'NATURAL_THREE_ARROWS_DOWN',
            'image': 'NATURAL_THREE_ARROWS_DOWN.png'
        }, {
            'name': 'SHARP_THREE_ARROWS_DOWN',
            'image': 'SHARP_THREE_ARROWS_DOWN.png'
        }, {
            'name': 'DOUBLE_SHARP_THREE_ARROWS_DOWN',
            'image': 'DOUBLE_SHARP_THREE_ARROWS_DOWN.png'
        }, {
            'name': 'DOUBLE_FLAT_THREE_ARROWS_UP',
            'image': 'DOUBLE_FLAT_THREE_ARROWS_UP.png'
        }, {
            'name': 'FLAT_THREE_ARROWS_UP',
            'image': 'FLAT_THREE_ARROWS_UP.png'
        }, {
            'name': 'NATURAL_THREE_ARROWS_UP',
            'image': 'NATURAL_THREE_ARROWS_UP.png'
        }, {
            'name': 'SHARP_THREE_ARROWS_UP',
            'image': 'SHARP_THREE_ARROWS_UP.png'
        }, {
            'name': 'DOUBLE_SHARP_THREE_ARROWS_UP',
            'image': 'DOUBLE_SHARP_THREE_ARROWS_UP.png'
        }, {
            'name': 'LOWER_ONE_SEPTIMAL_COMMA',
            'image': 'LOWER_ONE_SEPTIMAL_COMMA.png'
        }, {
            'name': 'RAISE_ONE_SEPTIMAL_COMMA',
            'image': 'RAISE_ONE_SEPTIMAL_COMMA.png'
        }, {
            'name': 'LOWER_TWO_SEPTIMAL_COMMAS',
            'image': 'LOWER_TWO_SEPTIMAL_COMMAS.png'
        }, {
            'name': 'RAISE_TWO_SEPTIMAL_COMMAS',
            'image': 'RAISE_TWO_SEPTIMAL_COMMAS.png'
        }, {
            'name': 'LOWER_ONE_UNDECIMAL_QUARTERTONE',
            'image': 'LOWER_ONE_UNDECIMAL_QUARTERTONE.png'
        }, {
            'name': 'RAISE_ONE_UNDECIMAL_QUARTERTONE',
            'image': 'RAISE_ONE_UNDECIMAL_QUARTERTONE.png'
        }, {
            'name': 'LOWER_ONE_TRIDECIMAL_QUARTERTONE',
            'image': 'LOWER_ONE_TRIDECIMAL_QUARTERTONE.png'
        }, {
            'name': 'RAISE_ONE_TRIDECIMAL_QUARTERTONE',
            'image': 'RAISE_ONE_TRIDECIMAL_QUARTERTONE.png'
        }, {
            'name': 'DOUBLE_FLAT_EQUAL_TEMPERED',
            'image': 'DOUBLE_FLAT_EQUAL_TEMPERED.png'
        }, {
            'name': 'FLAT_EQUAL_TEMPERED',
            'image': 'FLAT_EQUAL_TEMPERED.png'
        }, {
            'name': 'NATURAL_EQUAL_TEMPERED',
            'image': 'NATURAL_EQUAL_TEMPERED.png'
        }, {
            'name': 'SHARP_EQUAL_TEMPERED',
            'image': 'SHARP_EQUAL_TEMPERED.png'
        }, {
            'name': 'DOUBLE_SHARP_EQUAL_TEMPERED',
            'image': 'DOUBLE_SHARP_EQUAL_TEMPERED.png'
        }, {
            'name': 'QUARTER_FLAT_EQUAL_TEMPERED',
            'image': 'QUARTER_FLAT_EQUAL_TEMPERED.png'
        }, {
            'name': 'QUARTER_SHARP_EQUAL_TEMPERED',
            'image': 'QUARTER_SHARP_EQUAL_TEMPERED.png'
        }, {
            'name': 'SORI',
            'image': 'SORI.png'
        }, {
            'name': 'KORON',
            'image': 'KORON.png'
        }
        //,{ 'name': 'UNKNOWN', 'image': 'UNKNOWN.png' }
    ];

    readonly property var equivalences: [
        ['SHARP', 'NATURAL_SHARP'],
        ['FLAT', 'NATURAL_FLAT'],
        ['NONE', 'NATURAL'],
        ['SHARP2', 'SHARP_SHARP']
    ];

    function isEquivAccidental(a1, a2) {
        for (var i = 0; i < equivalences.length; i++) {
            if ((equivalences[i][0] === a1 && equivalences[i][1] === a2) ||
                (equivalences[i][0] === a2 && equivalences[i][1] === a1))
                return true;
        }
        return false;
    }

    function logElement(note, reached) {
        if (note.type == Element.NOTE)
            enrichNote(note);

        if (typeof reached === 'undefined') {
            reached = false;
        }

        addlog("..Properties:");
        if (!reached) {
            debugO(".... prop", note);
            var el = note.elements;
            if (el) {
                addlog("..Element objects (total:  " + el.length + "):");

                for (var j = 0; j < el.length; j++) {
                    var e = el[j];
                    addlog("... element " + (j + 1) + ": ");
                    debugO("......value", e);
                }
            }
        } else {
            debugO(".... prop", note.type);
        }

        var parent = note.parent;
        if (parent) {
            addlog("\nanalysing parent  ");
            logElement(parent, (note.type == deepest_parent) || reached);
        } else {
            addlog("\nno more parent");
        }

    }

    function addlog(text) {
        console.log(text);
        txtLog.text = txtLog.text + "\n" + text;
    }

    // function logObject(pre, e) {
    // var kkks = Object.keys(e);
    // for (var k = 0; k < kkks.length; k++) {
    // var val = e[kkks[k]];
    // if (val)
    // addlog(pre + " > " + kkks[k] + " = " + val);
    // if (typeof(val) === "object" && val != null && val.toString().indexOf("xyz") >= 0) { //FractionWrapper
    // logObject(pre + ">", val);
    // }
    // }
    // }

    function debugO(prefix, element, excludes, level) {

        if (typeof level === 'undefined') {
            level = 0;
        }

		// var label=".".repeat(level)+prefix;
		// var label="";
		// for(var i=1;i<=level;i++) {
			// label+=".";
		// }
		// label+=prefix;
		var label=prefix;
		
        var isinclude = false; // by default the exclude is an exclude list.otherwise it is an include

        if (typeof excludes === 'undefined') {
            excludes = default_excludes;
        } else if (!Array.isArray(excludes)) {
            excludes = [excludes];
        }

        if (typeof element === 'undefined') {
            // console.log(label + ": undefined");
            addlog(label + ": undefined");
        } else if (element === null) {
            // console.log(label + ": null");
            addlog(label + ": null");

        } else if (element.toString().indexOf("xyz") >= 0) {
            addlog(label + ": ????? XYZ ????");

        } else if (Array.isArray(element)) {
            for (var i = 0; i < element.length; i++) {
                debugO(prefix + "-" + i, element[i], excludes, level);
            }
        } else if (typeof element === 'object') { // && element.toString().indexOf("xyz") >= 0) {
            if (level < deepest_level) {
                var kys = Object.keys(element);
				// ce tri ne fonctionne pas, sauf qu'il garde bien type et name en 1er, pour le reste ...
                // kys = kys.sort(function (a, b) {
                    // var ia = minimum_set.indexOf(a);
                    // var ib = minimum_set.indexOf(b);
                    // if (ia == -1) {
                        // if (ib == -1) {
                            // return a - b;
                        // } else {
                            // return 1;
                        // }
                    // } else { // ia>=0
                        // if (ib == -1) {
                            // return -1;
                        // } else {
                            // return ia - ib;
                        // }
                    // }

                // });
                for (var i = 0; i < kys.length; i++) {
                    if ((excludes.indexOf(kys[i]) == -1) ^ isinclude) {
                        debugO(prefix + ": " + kys[i], element[kys[i]], excludes, level + 1);
                    } else {
                        addlog(label + ": " + kys[i] + ": ---");
                    }
                }

            } else if (level == deepest_level) {
                for (var i = 0; i < minimum_set.length; i++) {
                    var d = minimum_set[i];
                    if (typeof(element[d]) !== 'undefined')
                        debugO(prefix + ": " + d, element[d], excludes, level + 1);
                }
                addlog(label + ": +++");
            } else {
                addlog(label + ": ...");
            }
        } else {
            // console.log(label + ": " + element);
            addlog(label + ": " + element);
        }
    }
}
