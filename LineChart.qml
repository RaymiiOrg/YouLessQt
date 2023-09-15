/*
 * Copyright (c) 2023 Remy van Elst https://raymii.org
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15

Item {
    id: root

    property string title:  'title'
    property string yLabel: 'yLabel'
    property string xLabel: 'xLabel'

    property variant points: [] //{x: 0, y: 0, xLegend: 'text'}, {x: 1, y: 2, xLegend: 'text2'}]
    property string  color: 'navy'

    property double factor: Math.min(width, height)

    property double yInterval:  1
    property double yMax:  10
    property double yMin: 0

    function toYPixels(y) {
        return -plot.height / (yMax - yMin) * (y - yMin) + plot.height
    }

    property double xInterval: 1
    property double xMax: 10
    property double xMin:   0

    function toXPixels(x) {
        return plot.width  / (xMax - xMin) * (x - xMin)
    }

    onPointsChanged: { // auto scale
        var xMin = 0, xMax = 0, yMin = 0, yMax = 0
        for(var i = 0; i < points.length; i++) {
            if(points[i].y > yMax)  yMax = points[i].y
            if(points[i].y < yMin)  yMin = points[i].y
            if(points[i].x > xMax)  xMax = points[i].x
            if(points[i].x < xMin)  xMin = points[i].x
        }

        var yLog10 = Math.log(yMax - yMin) / Math.LN10
        root.yInterval = Math.pow(10, Math.floor(yLog10)) / 2
        root.yMax = Math.ceil( yMax / yInterval) * yInterval
        root.yMin = Math.floor(yMin / yInterval) * yInterval

        var xLog10 = Math.log(xMax - xMin) / Math.LN10
        root.xInterval = Math.pow(10, Math.floor(xLog10))
        root.xMax = Math.ceil( xMax / xInterval) * xInterval
        root.xMin = Math.floor(xMin / xInterval) * xInterval

        canvas.requestPaint()
    }

    Text {
        text: title
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 0.03 * factor
    }

    Text {
        text: yLabel
        font.pixelSize: 0.03 * factor
        y: 0.5 * (2 * plot.y + plot.height + width)
        rotation: -90
        transformOrigin: Item.TopLeft
    }

    Text {
        text: xLabel
        font.pixelSize: 0.03 * factor
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: plot.horizontalCenter
    }

    Item {
        id: plot

        anchors.fill: parent
        anchors.topMargin: 0.1 * factor
        anchors.bottomMargin: 0.2 * factor
        anchors.leftMargin: 0.15 * factor
        anchors.rightMargin: 0.1 * factor


        Repeater {
            model: Math.floor((yMax - yMin) / yInterval) + 1

            delegate: Rectangle {
                property double value: index * yInterval + yMin
                y: toYPixels(value)
                width: plot.width
                height: value? 1: 3
                color: 'black'

                Text {
                    text: parseFloat(parent.value.toPrecision(6)).toString()
                    anchors.right: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 0.01 * factor
                    font.pixelSize: 0.03 * factor
                }
            }
        }

        Repeater {
            model: Math.floor((xMax - xMin) / xInterval) + 1

            delegate: Rectangle {
                property double value: index * xInterval + xMin
                x: toXPixels(value)
                width: value ? 1 : 3
                height: plot.height
                color: 'black'

                Text {
                    text: root.points[parseInt(parent.value)] !== undefined ? root.points[parseInt(parent.value)].xLegend !== "" ? root.points[parseInt(parent.value)].xLegend : parseFloat(parent.value.toPrecision(6)).toString() : ""
                    anchors.top: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: 0.01 * factor
                    font.pixelSize: 0.03 * factor
                }
            }
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var context = getContext("2d")
                context.clearRect(0, 0, width, height)
                context.strokeStyle = color
                context.lineWidth   = 0.005 * factor
                context.beginPath()
                for(var i = 0; i < points.length; i++)
                    context.lineTo(toXPixels(points[i].x), toYPixels(points[i].y))
                context.stroke()
            }
        }
    }
}
