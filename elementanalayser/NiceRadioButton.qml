import QtQuick 2.9
import QtQuick.Controls 2.2

RadioButton {
	id: control
    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 13
        border.color: control.down ? "#555555" : "#929292"

        Rectangle {
            width: 10
            height: 10
            x: 5
            y: 5
            radius: 7
            color: control.down ? "#555555" : "black"
            visible: control.checked
        }
    }
}