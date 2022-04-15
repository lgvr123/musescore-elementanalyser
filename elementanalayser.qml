import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import "elementanalayser/elementanalayser.js" as Debug

MuseScore {
    menuPath: "Plugins.Element analyser"
    description: "Retrieve all the properties about the selected element"
    version: "1.0.0"
    pluginType: "dialog"
    requiresScore: true
    width: 600
    height: 600

    /** the notes to which the fingering must be made. */
    property var __notes: [];

    // -----------------------------------------------------------------------
    // --- Read the score ----------------------------------------------------
    // -----------------------------------------------------------------------
    onRun: {

        Debug.addLogger(
            function (text) {
            txtLog.text = txtLog.text + "\n" + text;
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

        var note = el[0];
        //addlog("analysing the selected element " + (i + 1) + " (" + note.name + " [" + note.type + "]" + ")");
        //if (note.type!=84) continue;
        Debug.debugO("first element", note);

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
}
