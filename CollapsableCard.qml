import QtQuick 2.15
import QtQuick.Controls 2.15

Column {
    id: root
    default property alias children: content.children
    required property string title
    property color titleBgColor:  "#e0e0e0"
    property color titleBgColorPressed: "#cfcfcf"
    property color titleBorderColor: titleBgColor
    property bool collapsed: true

    Button {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        contentItem: Text {
            anchors.fill: parent
            anchors.margins: 5
            text: root.title
            horizontalAlignment : Text.AlignHCenter
            minimumPixelSize: 16
            fontSizeMode: Text.Fit
            wrapMode: Text.WordWrap
            elide: Text.ElideMiddle
        }

        onClicked: root.collapsed = !root.collapsed
        background: Rectangle {
            color: parent.down ? titleBgColorPressed : titleBgColor
            border.color: titleBorderColor
            border.width: 1
            radius: 6
        }
    }

    Pane {
        id: contentPane

        visible: height > 0
        height: !root.collapsed ? implicitHeight : 0

        Behavior on height {
            NumberAnimation {
                easing.type: Easing.InOutQuad
            }
        }

        clip: true
        anchors.left: parent.left
        anchors.right: parent.right

        Column {
            id: content
            anchors.right: parent.right
            anchors.left: parent.left
            spacing: 10
        }
    }
}
