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
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: root
    width: 800
    height: 1000
    visible: true
    title: qsTr("YouLessQt 1.1 by Remy van Elst, raymii.org. License: GNU GPLv3")

    property var response: undefined

    property var pwrValues: []
    property int pwrCount: 0
    property int pwrMaxCount: 300

    property int rawMaxCount: 300
    property var rawValues: []
    property int rawCount: 0
//    property int rawLowest: 9999999
//    property int rawAvg: 0
//    property int suggestedLwValue: 105

    property int lvlMaxCount: 300
    property var lvlValues: []
    property int lvlCount: 0

    property bool showPwrGraph: true
    property bool showRawGraph: true

    property bool getDeviceInfoOnce: false


    function doGetRequest(url) {
        var xmlhttp = new XMLHttpRequest()

        xmlhttp.onreadystatechange = function () {
            if (xmlhttp.readyState === XMLHttpRequest.DONE) {
                if(xmlhttp.status >= 200 && xmlhttp.status < 400) {
                    //                console.log("resp: " + JSON.stringify(xmlhttp.responseText))
                    try {
                        response = JSON.parse(xmlhttp.responseText)
                    } catch(e) {
                        errorText.text = "JSON parse error (of net ge-reboot)"
                        getTimer.stop()
                    }
                } else {
                    errorText.text = "HTTP Error: " + xmlhttp.statusText + "; Status code: " + xmlhttp.status
                    getTimer.stop()
                }
            }
        }
        xmlhttp.ontimeout = function() { errorText.text = "HTTP Timeout!"; getTimer.stop() };
        xmlhttp.onerror = function() {  errorText.text = "HTTP ERROR!"; getTimer.stop() };
        xmlhttp.open("GET", url, true)
        xmlhttp.timeout = 4000 // 4 sec
        xmlhttp.send()
    }




    onResponseChanged: {
        const average = arr => arr.reduce( ( previous, current ) => previous + current, 0 ) / arr.length;

        if(response !== undefined) {
            var minutes = new Date().getMinutes();
            minutes = minutes > 9 ? minutes : '0' + minutes;
            var hours = new Date().getHours();
            hours = hours > 9 ? hours : '0' + hours;
            var timeText = hours + ":" + minutes;

            // /e api, device info
            if(response.hasOwnProperty("model")) deviceModelLabel.text = "Model: " + response.model
            if(response.hasOwnProperty("fw")) deviceFwLabel.text = "Fw: " + response.fw
            if(response.hasOwnProperty("mac")) deviceMacLabel.text = "MAC: " + response.mac

            // /V?h=1 api (minute log)
            if(response.hasOwnProperty("val") && Array.isArray(response.val) && response.val.length > 0) {
                pwrValues.push({x: pwrCount, y: parseInt(response.val[0]), xLegend: "-1m"})
                pwrCount++
            }

            // /a api, only one with raw values
            if(response.hasOwnProperty("pwr")) {
                if(pwrValues.length > 0 && pwrValues.slice(-1).pop().y !== response.pwr) {
                    pwrValues.push({x: pwrCount, y: response.pwr, xLegend: timeText})
                    pwrCount++                    
                }
            }
            if(response.hasOwnProperty("raw")) {                
                rawValues.push({x: rawCount, y: response.raw, xLegend: timeText})
                rawCount++

//                // https://web.archive.org/web/20230917145547/https://gathering.tweakers.net/forum/view_message/50504265
//                rawAvg = average(rawValues.map((pwrV) => pwrV.y))
//                if(response.raw < rawLowest) {
//                    rawLowest = response.raw
//                    console.log("low: " + rawLowest)
//                }
//                console.log("avg: " + rawAvg)
//                suggestedLwValue = Math.max(105, ((rawAvg / Math.max(1, rawLowest)) - 10));
//                console.log("sug: " + suggestedLwValue)
            }

            if(response.hasOwnProperty("lvl")) {
                lvlValues.push({x: lvlCount, y: response.lvl, xLegend: timeText})
                lvlCount++
                lvlLabel.text = response.lvl + "%"

            }
            if(response.hasOwnProperty("cnt")) cntLabel.text = response.cnt + " kWh"
            if(response.hasOwnProperty("pwr")) pwrLabel.text = response.pwr + " W"
            if(response.hasOwnProperty("dev")) devLabel.text = response.dev
            if(response.hasOwnProperty("det")) detLabel.text = response.det
        }
    }

    onPwrCountChanged: {
        if(pwrCount > pwrMaxCount) {
            pwrValues = pwrValues.map(function(point){return {x: point.x - 1, y: point.y, xLegend: point.xLegend};});
            pwrValues = pwrValues.slice(1)
            pwrCount--;
        }
        wattChart.points = pwrValues
    }

    onRawCountChanged: {
        if(rawCount > rawMaxCount) {
            rawValues = rawValues.map(function(point){return {x: point.x - 1, y: point.y, xLegend: point.xLegend};});
            rawValues = rawValues.slice(1)
            rawCount--;
        }
        rawChart.points = rawValues
    }

    onLvlCountChanged: {
        if(lvlCount > lvlMaxCount) {
            lvlValues = lvlValues.map(function(point){return {x: point.x - 1, y: point.y, xLegend: point.xLegend};});
            lvlValues = lvlValues.slice(1)
            lvlCount--;
        }
        lvlChart.points = lvlValues
    }


    Timer {
        id: getTimer
        interval: 500
        running: false
        repeat: true
        onTriggered: {
            // get device info and history only once
            if(!getDeviceInfoOnce) {
                doGetRequest("http://" + youLessIP.text + "/d")
                doGetRequest("http://" + youLessIP.text + "/V?h=1")
                getDeviceInfoOnce = true
            }

            doGetRequest("http://" + youLessIP.text + "/a?f=j")
        }
    }



    TabBar {
        id: bar
        width: parent.width
        height: 40
        z: 2
        Repeater {
            model: ["YouLessQt", "Help"]

            TabButton {
                text: modelData
                width: Math.max(100, bar.width / 2)
            }
        }
    }


    StackLayout {
        anchors.top: bar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        currentIndex: bar.currentIndex

        ScrollView {
            id: homeTab
            contentWidth: availableWidth // only allow horizontal scrolling
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 5

            GridLayout {
                id: infoRow
                Layout.preferredWidth: 400
                Layout.alignment: Qt.AlignTop
                Layout.margins: 5
                rowSpacing: 5
                columnSpacing: 5
                columns: root.width < 400 ? 1 : 3
                rows: root.width < 400 ? 3 : 1

                TextField {
                    id: youLessIP
                    placeholderText: "YouLess IP (192.168.x.y)"
                    onAccepted: startStopButton.clicked()
                }


                Button {
                    id: startStopButton
                    text: getTimer.running ? "Stop" : "Start"
                    Layout.minimumWidth: 120
                    enabled: youLessIP.text !== ""
                    onClicked: {
                        errorText.text = ""
                        if(getTimer.running) {
                            getTimer.stop()
                            getDeviceInfoOnce = false
                        } else {
                            getTimer.start()
                        }
                    }
                }

                Button {
                    text: "Clear"
                    Layout.minimumWidth: 120
                    onClicked: {
                        pwrCount = 0
                        pwrValues = []
                        rawCount = 0
                        rawValues = []
                        lvlCount = 0
                        lvlValues = []
                    }
                }
            }




                Item {
                    Layout.preferredHeight: 2
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    color: '#eee'
                }
            }


            GridLayout {
                id: deviceInfoRow
                Layout.preferredWidth: 500
                Layout.margins: 5
                rowSpacing: 5
                columnSpacing: 5
                Layout.alignment: Qt.AlignTop
                columns: root.width < 400 ? 1 : 4
                rows: root.width < 400 ? 4 : 1

                Text {
                    id: errorText
                    visible: text !== ""
                    color: 'red'
                }

                Text {
                    id: deviceModelLabel
                    text: "Model: "
                }
                Text {
                    id:  deviceFwLabel
                    text: "Fw: "
                }
                Text {
                    id:  deviceMacLabel
                    text: "MAC: "
                }
            }


            Rectangle {
                Layout.preferredHeight: 2
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: parent.width
                color: '#eee'
            }

            GridLayout {
                id: currentValuesRow
                Layout.preferredWidth: 500
                Layout.alignment: Qt.AlignTop
                Layout.margins: 5
                rowSpacing: 5
                columnSpacing: 5
                columns: root.width < 400 ? 2 : 5
                rows: root.width < 400 ? 5 : 2

                Text {
                    id: cntLabel // counter in kWh
                    textFormat: Text.RichText
                    text: "... kWh"
                }

                Text {
                    id:  detLabel // puls / meetbericht detectie indicatie
                    color: 'red'
                    textFormat: Text.RichText
                }

                Text {
                    visible: !detLabel.visible
                    color: 'white'
                    text: "."
                }

                Text {
                    id:  lvlLabel // moving average level (intensity of reflected light on analog meters)
                    textFormat: Text.RichText
                    text: "... %"
                }

                Text {
                    id:  devLabel // deviation of reflection
                    textFormat: Text.RichText
                    text: "( ... %)"
                }


                Text {
                    id: pwrLabel //  Pwer consumption in Watt
                    textFormat: Text.RichText
                    text: "... W"
                }
            }

            Item {
                Layout.preferredHeight: 2
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    color: '#eee'
                }
            }

            Item {
                visible: showRawGraph
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: 500


                LineChart {
                    id: rawChart
                    anchors.fill: parent

                    visible:  showRawGraph

                    title:  'Ruwe 10-bit licht sensor reflectie waarde'
                    yLabel: 'Raw'
                    xLabel: 'Tijd'
                    color:  '#BDCF32'
                    Rectangle {
                        anchors.fill: parent
                        color: '#8BD3C7'
                        opacity: .2
                    }
                }
            }


            Item {
                Layout.preferredHeight: 2
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    color: '#eee'
                }
            }



            GridLayout {
                id: setLightSensorRow
                Layout.preferredWidth: 400
                Layout.alignment: Qt.AlignTop
                Layout.margins: 5
                rowSpacing: 5
                columnSpacing: 5
                columns: root.width < 400 ? 1 : 2
                rows: root.width < 400 ? 2 : 1

                TextField {
                    id: lwValue
                    placeholderText: "LW waarde (default 180)"
                    validator: IntValidator{bottom: 105; top: 500;}
                    onAccepted: setlwValueButton.clicked()
                }


                Button {
                    id: setlwValueButton
                    text: "Set LW value"
                    enabled: lwValue.text !== "" && lwValue.acceptableInput
                    onClicked: {
                        doGetRequest("http://" + youLessIP.text + "/M?lw=" + lwValue.text)
                    }
                }
            }

            Item {
                Layout.preferredHeight: 2
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    color: '#eee'
                }
            }

            Item {
                visible: showRawGraph
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: 500


                LineChart {
                    id: lvlChart
                    anchors.fill: parent

                    visible:  showRawGraph
                    title:  'Licht sensor niveau in procent (moving average)'
                    yLabel: 'percentage'
                    xLabel: 'Tijd'
                    color:  '#CA472F'
                    Rectangle {
                        anchors.fill: parent
                        color: '#E3DBF7'
                        opacity: .2
                    }
                }
            }

            Item {
                Layout.preferredHeight: 2
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    color: '#eee'
                }
            }

            Item {
                visible: showPwrGraph
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: 500


                LineChart {
                    id: wattChart
                    anchors.fill: parent
                    title:  'Actueel Vermogen'
                    yLabel: 'Watt'
                    xLabel: 'Tijd'
                    color:  '#9B19F5'

                    Rectangle {
                        anchors.fill: parent
                        color: '#b2e061'
                        opacity: .2
                    }
                }
            }


            GridLayout {
                id: moreButtonsRow
                Layout.preferredWidth: 500
                Layout.alignment: Qt.AlignTop
                Layout.margins: 5
                rowSpacing: 5
                columnSpacing: 5
                columns: root.width < 400 ? 1 : 5
                rows: root.width < 400 ? 5 : 1

                Button {
                    text: showPwrGraph ? "Hide Power" : "Show Power"
                    onClicked: showPwrGraph = !showPwrGraph
                }

                Button {
                    text: showRawGraph ? "Hide Raw" : "Show Raw"
                    onClicked: showRawGraph = !showRawGraph
                }

                Button {
                    text: "Herstart YouLess"
                    enabled: youLessIP.text !== ""
                    onClicked: {
                        getTimer.stop()
                        doGetRequest("http://" + youLessIP.text + "/S?rb=")
                    }
                }
            }

            Item {
                Layout.preferredHeight: 2
                Layout.preferredWidth: parent.width
                Layout.alignment: Qt.AlignTop

                Rectangle {
                    anchors.fill: parent
                    color: '#eee'
                }
            }


            Item {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: 600

                    Text {
                        anchors.fill: parent
                        text: "YouLessQt 1.1 by Remy van Elst\nLicense: GNU GPLv3"
                        color: "#bbb"
                    }
                }


            }
        }


        ScrollView {
            id: helpTab
            contentWidth: availableWidth // only allow horizontal scrolling
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 5


                Text {
                    Layout.preferredWidth: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    textFormat: TextEdit.MarkdownText
                    text: "**Dit is een onofficiele applicatie, niet door YouLess / PostFossil gemaakt.**

<p/>

Helpt de YouLess energiemeter goed op de analoge
(draaischijf) meter plakken door de ruwe sensorwaarde
en relevante sensorwaardes te tonen zodat men kan zien
wanneer een puls gedetecteerd wordt, zonder een Windows 7
gadget te installeren. Ook is hiermee de LW waarde direct
aan te passen op de YouLess, waarna het effect direct in
de grafiek te zien is. Gezien dit een Android applicatie is
(evenals Windows) is dit makkelijker direct in de meterkast
te gebruiken dan een PC gadget.

<p/>

Ik heb deze applicatie in een paar avonden in elkaar gezet omdat
de YouLess pulsen miste van mijn draaischijf. Na een paar keer
opnieuw plakken en juist uitlijnen werden er geen pulsen meer
gemist. Dezelfde dipjes zoals op onderstaand voorbeeld-plaatje
zullen in de grafieken hier ook te zien zijn.

<p/>

Vul het IP of de hostname van de YouLess in, druk op Start en
de grafieken worden zichtbaar, evenals wat model informatie
(MAC, firmware, etc) en de ruwe waardes. De rode stip geeft
aan dat er een puls gedetecteerd is. Met de 'Set LW' knop
kun je LW waarde (zoals hieronder beschreven) direct instellen.

<p/>

De huidige LW waarde is niet op te vragen via de API, de default
is 180.

<p/>

Meer informatie over deze methode:

<p/>

https://gathering.tweakers.net/forum/view_message/43732209

<p/>

Quote:

<p/>

> In België zijn analoge elektriciteitsmeters vaak in een extra
(semi)transparant kunstof kast ondergebracht. Is die bij jou ook het geval?

<p/>

> De afstand tussen Youless en draaischijf is daardoor vaak groter dan
zonder de plastiek kast. Door het zwakkere signaal is het vaak nodig om
de gevoeligheid van de Youless gevoeliger af te stellen voor deze situatie.

<p/>

> Wij hebben een Windows tool (in de vorm van een Windows gadget) waarmee
de reflectie van de draaischijf zichtbaar gemaakt kan worden in een
grafiek. Deze tool is behulpzaam zijn bij het afstellen van de
gevoeligheid Deze tool kan hier worden gedownload:

<p/>

> http://www.youless.nl/tl_files/downloads/rawmon-0.2.zip

<p/>

> Indien u Windows 8 gebruikt, dan kan de raw monitor gadget worden
gebruikt met behulp van de 8gadget pack:

<p/>

> http://www.youless.nl/blogpost/items/gadget-windows-8.html

<p/>

> De Youless werkt zo dat hij standaard een dip in de gereflecteerde
lichtsterkte van ongeveer 45% als een puls telt. Met de Windows tool
ziet de grafiek er normaal gesproken zo uit:

<p/>

"
                }

                Image {
                    id: img
                    width: 400
                    height: 300
                    source: "qrc:///siemens-red.png"
                }


                Text {
                    Layout.preferredWidth: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    textFormat: TextEdit.MarkdownText
                    text: "
> Er is hier duidelijk een korte scherpe dip te zien in het signaal
wanneer het streepje langskomt. Hoe duidelijker de dip (relatief)
zichtbaar is hoe beter. Als het gemiddelde input niveau zelf laag is, is
dat op zich overigens geen probleem. Als de dip maar goed te
onderscheiden is.

<p/>

> Deze dip zal door de grotere afstand minder duidelijk zijn indien er
sprake is van een extra plastiek kast. De drempelwaarde parameter lw kan
worden bijgesteld door de volgende url in een browser in te geven (het
voorbeeld IP adres 1.2.3.4 dient hier nog vervangen te worden door het
eigen Youless IP adres) :

<p/>

> http://1.2.3.4/M?lw=105

<p/>

> Wat dit betekent is dat de Youless een dip van 100/105=0.95 (ofwel een
5% relatieve daling) van het gemiddelde reflectieniveau als een puls zal
zien. Af fabriek is de waarde van lw gelijk aan 180, dus met 105 is de
gevoeligheid flink hoger. De waarde van lw moet tenminste 101 zijn.

<p/>

> De voorgestelde parameter waarde 105 werkt meestal goed bij meters in
een extra plastiek kast. Vanuit de reflectie grafiek kan indien nodig
worden afgeleid wat een optimale waarde is voor lw.

<p/>

> Mocht u nog vragen hebben, laat het ons dan gerust weten.


Einde Quote
<p/>

Als aanvulling nog een afbeelding van een verkeerd uitgelijnde YouLess
waarbij geen pulsen gedetecteerd werden. Via:
https://web.archive.org/web/20230917145340/https://gathering.tweakers.net/forum/view_message/54740479
<p />
"
                }
                Image {
                    width: 400
                    height: 300
                    source: "qrc:///rawmon-wrong.png"
                }


                Text {
                    Layout.preferredWidth: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignLeft
                    textFormat: TextEdit.MarkdownText
                    text: "
<p/>
License: GNU GPLv3
<p/>

Author: Remy van Elst (https://raymii.org).
<p/>

Source: https://github.com/RaymiiOrg/YouLessQt
</p>

אֶשָּׂא עֵינַי אֶל־הֶהָרִים מֵאַיִן יָבֹא עֶזְרִֽי׃


---
"
                }
            }
        }

    }


}





