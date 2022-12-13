import QtQuick 2.9
import QtQuick.Controls 2.2

/**
 * 1.0: Only setting the right color in the darkmode
 */
Label {
    id: control
    color: sysActivePalette.text

    SystemPalette {
        id: sysActivePalette;
        colorGroup: SystemPalette.Active
    }

}
