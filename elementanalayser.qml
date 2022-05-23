import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import "elementanalayser/elementanalayser.js" as Debug
import "elementanalayser"
import Qt.labs.settings 1.0

/**********************
/* Parking B - MuseScore - Element analyser
/* v1.1.1
/* ChangeLog:
/* 	- 1.0.0: Initial release
/* 	- 1.1.0: Striketrough of non investigated elements
/* 	- 1.1.0: Choice between Non Nulls / All analysis
/* 	- 1.1.1: Les QVariants (objets sans propriétés) n'étaient pas affichés
/**********************************************/
MuseScore {
    menuPath: "Plugins.Element analyser"
    description: "Retrieve all the properties about the selected element"
    version: "1.0.0"
    pluginType: "dialog"
    requiresScore: true
    width: 600
    height: 650

    /** the notes to which the fingering must be made. */
    property var element: null;

    property bool analyzeRunning: false

    Settings {
        id: settings
        category: "ElementAnalyser"
        property alias autorun: autorun.checked
        property alias analyse: rdbAnalyseAll.checked
    }

    // -----------------------------------------------------------------------
    // --- Read the score ----------------------------------------------------
    // -----------------------------------------------------------------------
    onRun: {
        analyzeRunning = false;
		if (!rdbAnalyseAll.checked && !rdbAnalyseNonNull.checked) rdbAnalyseNonNull.checked=!rdbAnalyseAll.checked;
        Debug.addLogger(
            function (text) {
            var split = text.match(/^([\s.-]*)(.*): ---$/m);
            var recompose;
            if (split === null)
                recompose = text;
            else {
                recompose = split[1] + "<s>" + split[2] + "</s>";
            }
            txtLog.text = txtLog.text + "\n" + recompose;
        });
        // analysing whatever is selected
        var selection = curScore.selection;

        var el = selection.elements;
        if (el.length == 0) {
            invalidSelectionDialog.open();
            return;
        } else if (el.length > 1) {
            console.warn("Limit analyze to first element");
        }

        element = el[0];

        console.log("initialization done");

        if (settings.autorun) {
            analyzeRunning = true;
            timer.start();
        }

    }
    function analyze() {

        if (rdbAnalyseAll.checked) {
            Debug.debugO("All", element);
        } else if (rdbAnalyseNonNull.checked) {
            Debug.debugNonNulls("Non null properties", element);
        } else if (rdbAnalyseTick.checked) {
            Debug.debugNonNulls("Tick", element, {
                filterList: ["tick"],
                isinclude: true,
                maxlevel: 0,
                stopat: Element.SEGMENT, // never stop
                hideExcluded: true
            });
        }
        analyzeRunning = false;
    }
    // Component.onCompleted: console.log("Window ready!")

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
            // Component.onCompleted: console.log("ScrollV ready!")
            TextArea {
                id: txtLog
                text: ""
                selectByMouse: true
                selectByKeyboard: true
                cursorVisible: true
                readOnly: true
                focus: true
                textFormat: Text.RichText
                placeholderText: "here will come the selected element details..."
                background: Rectangle {
                    color: "white"
                    border.color: "#C0C0C0"
                }
            }

            ScrollBar.vertical: ScrollBar {
                parent: view
                width: 20
                x: view.mirrored ? 0 : view.width - width
                y: view.topPadding
                height: view.availableHeight
                active: true
                interactive: true
                visible: !analyzeRunning
            }

        }

        SmallCheckBox {
            id: autorun
            text: "Automatically run with last settings on next startup"
            checked: false

        }

        RowLayout {
            Label {
                text: "Analyse mode:"
            }
            // ButtonGroup {
            // id: grpAnalyseType
            // }
            NiceRadioButton {
                id: rdbAnalyseAll
                text: qsTr("All")
                checked: true
                //ButtonGroup.group: bar
            }
            NiceRadioButton {
                id: rdbAnalyseNonNull
                text: qsTr("Non null")
                //ButtonGroup.group: bar
            }
            NiceRadioButton {
                id: rdbAnalyseTick
                text: qsTr("Tick")
                //ButtonGroup.group: bar
            }
        }
        Item { // buttons row // DEBUG was Item
            Layout.fillWidth: true
            Layout.preferredHeight: btnAnalyse.implicitHeight

            RowLayout {
                id: panButtons
                anchors.fill: parent
                Item { // spacer // DEBUG Item/Rectangle
                    id: spacer
                    implicitHeight: 10
                    Layout.fillWidth: true
                }

                Button {
                    id: btnAnalyse
                    text: "Analyse!"
					enabled: !analyzeRunning &&  (rdbAnalyseAll.checked || rdbAnalyseNonNull.checked || rdbAnalyseTick.checked)

                    onClicked: {
                        analyzeRunning = true;
                        timer.start();
                    }
                }
                Button {
                    id: btnClose
                    text: "Close"

					enabled: !analyzeRunning

                    onClicked: Qt.quit()
                }
            }
        } // button rows

    }

    BusyIndicator {
        id: busyIndicator
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: 60
        height: 60
        running: analyzeRunning
        visible: analyzeRunning
    }



    Timer {
        id: timer;
        interval: 250;
        running: false;
        repeat: false
        onTriggered: {
            txtLog.text = "<html>";
            console.log("timer triggered");
            analyze();
            txtLog.text = txtLog.text + "\n" + "</html>";
        }
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
}
