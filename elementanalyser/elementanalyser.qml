import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import "elementanalyser.js" as Debug
import Qt.labs.settings 1.0

/**********************
/* Parking B - MuseScore - Element analyser
/* ChangeLog:
/* 	- 1.0.0: Initial release
/* 	- 1.1.0: Striketrough of non investigated elements
/* 	- 1.1.0: Choice between Non Nulls / All analysis
/* 	- 1.1.1: Les QVariants (objets sans propriétés) n'étaient pas affichés
/* 	- 1.1.2: New "Tick" search option
/* 	- 1.1.3: Qt.quit issue
/* 	- 1.1.4: new Parent tree and Custom options
/* 	- 1.2.0: Port to MuseScore 4.0
/* 	- 1.2.0: New plugin folder strucutre
/* 	- 1.2.1: Darkmode
/**********************************************/
MuseScore {
    menuPath: "Plugins.Element analyser"
    description: "Retrieve all the properties about the selected element"
    version: "1.2.1"
    pluginType: "dialog"
    requiresScore: true
    width: 600
    height: 650

    id: mainWindow
    
    Component.onCompleted : {
        if (mscoreMajorVersion >= 4) {
            mainWindow.title = "Element analyser";
            mainWindow.thumbnailName = "logo.png";
            mainWindow.categoryCode = "analysis";
        }
    }    

    property bool analyzeRunning: false
    
    property var element: null

    Settings {
        id: settings
        category: "ElementAnalyser"
        property alias autorun: autorun.checked
        property int analyse
    }

    // -----------------------------------------------------------------------
    // --- Read the score ----------------------------------------------------
    // -----------------------------------------------------------------------
    onRun: {
        analyzeRunning = false;
        
        var lastoption = optionsGroup.buttons[settings.analyse];
        if (lastoption) lastoption.checked=true;
        
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

        if (settings.autorun) {
            if (getSelection()) {
                analyzeRunning=true;
                timer.start();
            }
        }

    }
    
    /*
    * Search for the selection and launch the analyze
    */
    function getSelection() {

        // Searching for a selection
        var selection = curScore.selection;

        if (!selection || selection.elements.length===0) {
            invalidSelectionDialog.open();
            element = null;
            return false;
        } 

        var el = selection.elements;
        if (el.length > 1) {
            console.warn("Limit analyze to first element: ");
            for(var i=0;i<el.length;i++) {
                console.log("\t"+el[i].userName());
            }
        }
        
        element = el[0];
        return true;
        
    }

    function analyze() {

        if(!element) return;
        
        // Performing the analyze
        if (rdbAnalyseAll.checked) {
            Debug.debugO(element.userName()+" === all", element);
        } else if (rdbAnalyseNonNull.checked) {
            Debug.debugNonNulls(element.userName()+" === non null properties", element);
        } else if (rdbAnalyseTick.checked) {
            Debug.debugNonNulls(element.userName()+" === tick", element, {
                filterList: ["tick"],
                isinclude: true,
                maxlevel: 0,
                stopat: Element.SEGMENT, // stop at segment (where tick is located)
                hideExcluded: true
            });
        } else if (rdbParentHood.checked) {
            Debug.debugNonNulls(element.userName()+" === parents' tree", element, {
                filterList: [],
                isinclude: true,
                maxlevel: 0,
                stopat: -1, // never stop
                hideExcluded: true
            });
            
        } else if (rdbCustom.checked) {
            // ////// CUSTOM ANALYSE ///////
            Debug.debugO(element.userName()+" === CUSTOM", element, {
                filterList: ["elements", "page", "prevMeasure", "nextMeasure"],
                isinclude: true,
                maxlevel: 1,
                stopat: Element.MEASURE, // never stop
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
            NiceLabel {
                text: "Analyse mode:"
            }
            ButtonGroup {
                id: optionsGroup
            }
            NiceRadioButton {
                id: rdbAnalyseAll
                text: qsTr("All")
                checked: true
                ButtonGroup.group: optionsGroup
            }
            NiceRadioButton {
                id: rdbAnalyseNonNull
                text: qsTr("Non null")
                ButtonGroup.group: optionsGroup
            }
            NiceRadioButton {
                id: rdbAnalyseTick
                text: qsTr("Tick")
                ButtonGroup.group: optionsGroup
            }
            NiceRadioButton {
                id: rdbParentHood
                text: qsTr("Parenthood")
                ButtonGroup.group: optionsGroup
            }
            NiceRadioButton {
                id: rdbCustom
                text: qsTr("Custom")
                ToolTip.visible: hovered
                ToolTip.text: "Custom analyze to be defined directly in the code"
                ButtonGroup.group: optionsGroup
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
                    enabled: !analyzeRunning && (rdbAnalyseAll.checked || rdbAnalyseNonNull.checked || rdbAnalyseTick.checked || rdbParentHood.checked || rdbCustom.checked)

                    onClicked: {
                        if (getSelection()) {
                            analyzeRunning=true;
                            timer.start();
                        }
                    }
                }
                Button {
                    id: btnClose
                    text: "Close"

                    enabled: !analyzeRunning

                    onClicked: {
                        for (var i = 0; i < optionsGroup.buttons.length; i++) {
                            if (optionsGroup.buttons[i].checked) {
                                settings.analyse = i;
                                break;
                            }
                        }
                        mainWindow.parent.Window.window.close(); //Qt.quit()
                    }
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
            mainWindow.parent.Window.window.close(); //Qt.quit()
        }
    }
    SystemPalette {
        id: sysActivePalette;
        colorGroup: SystemPalette.Active
    }
}