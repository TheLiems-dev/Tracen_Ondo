import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel

Rectangle {
    width: 1280
    height: 720
    color: "#1a1b26"

    property real scaleFactor: Math.min(width / 1920, height / 1080)
    property bool showLogin: false
    property bool capsLockOn: false
    property bool isAudioMuted: true

    FontLoader { source: "font/MaterialSymbolsRounded.ttf" }

    AudioOutput {
        id: audioOutput
        muted: isAudioMuted
    }

    Item {
        id: bgGroup
        anchors.fill: parent
        z: 0
        layer.enabled: true
        layer.smooth: true

        MediaPlayer {
            id: player
            source: "background.mp4"
            audioOutput: audioOutput
            videoOutput: video
            loops: MediaPlayer.Infinite
            autoPlay: true
        }

        VideoOutput {
            id: video
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.4
        }
    }

    GaussianBlur {
        id: bgBlur
        anchors.fill: parent
        source: bgGroup
        radius: 0
        samples: 17
        z: 1
        opacity: 0

        Behavior on radius {
            NumberAnimation { duration: 700; easing.type: Easing.InOutQuad }
        }
        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }
    }

    Item {
        id: clockContainer
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 40 * scaleFactor
            leftMargin: 44 * scaleFactor
        }
        z: 3

        property string timeStr: "00:00"
        property string dateStr: ""
        property string cityName: ""
        property string weatherStr: ""
        property string aqiStr: ""
        property bool dataLoaded: false

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: updateClock()
        }

        Timer {
            interval: 600000; running: true; repeat: true
            onTriggered: fetchLocation()
        }

        function updateClock() {
            var d = new Date()
            var h = d.getHours().toString().padStart(2, "0")
            var m = d.getMinutes().toString().padStart(2, "0")
            timeStr = h + ":" + m

            var days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
            dateStr = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear()

            timePulseAnim.restart()
        }

        function fetchLocation() {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "http://ip-api.com/json")
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    var resp = JSON.parse(xhr.responseText)
                    if (resp.status === "success") {
                        cityName = resp.city + ", " + resp.countryCode
                        fetchWeather(resp.lat, resp.lon)
                    }
                }
            }
            xhr.send()
        }

        function fetchWeather(lat, lon) {
            var wxhr = new XMLHttpRequest()
            wxhr.open("GET", "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,relative_humidity_2m,weather_code,apparent_temperature&timezone=auto")
            wxhr.onreadystatechange = function() {
                if (wxhr.readyState === 4 && wxhr.status === 200) {
                    var resp = JSON.parse(wxhr.responseText)
                    if (resp.current) {
                        var t = Math.round(resp.current.temperature_2m)
                        var ft = Math.round(resp.current.apparent_temperature)
                        var h = resp.current.relative_humidity_2m
                        var wc = resp.current.weather_code
                        weatherStr = t + "°  " + weatherName(wc)
                        dataLoaded = true
                    }
                }
            }
            wxhr.send()

            var axhr = new XMLHttpRequest()
            axhr.open("GET", "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + lat + "&longitude=" + lon + "&current=european_aqi")
            axhr.onreadystatechange = function() {
                if (axhr.readyState === 4 && axhr.status === 200) {
                    var resp = JSON.parse(axhr.responseText)
                    if (resp.current) {
                        var aqi = Math.round(resp.current.european_aqi)
                        aqiStr = "AQI " + aqi + " (" + aqiLabel(aqi) + ")"
                    }
                }
            }
            axhr.send()
        }

        function weatherName(c) {
            if (c === 0) return "Clear"
            if (c <= 3) return c === 1 ? "Mostly clear" : c === 2 ? "Partly cloudy" : "Overcast"
            if (c === 45 || c === 48) return "Fog"
            if (c >= 51 && c <= 55) return "Drizzle"
            if (c >= 61 && c <= 65) return "Rain"
            if (c >= 71 && c <= 75) return "Snow"
            if (c >= 80 && c <= 82) return "Showers"
            if (c >= 95) return "T-storm"
            return "--"
        }

        function aqiLabel(v) {
            if (v <= 20) return "Good"
            if (v <= 40) return "Fair"
            if (v <= 60) return "Moderate"
            if (v <= 80) return "Poor"
            if (v <= 100) return "Very poor"
            return "Extreme"
        }

        Component.onCompleted: {
            updateClock()
            fetchLocation()
        }

        Column {
            spacing: 2 * scaleFactor

            Item {
                width: Math.max(timeGlow.width, timeText.width)
                height: Math.max(timeGlow.height, timeText.height)

                Text {
                    id: timeGlow
                    text: clockContainer.timeStr
                    color: "#7aa2f7"
                    font.pointSize: 56 * scaleFactor
                    font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                    font.weight: Font.Bold
                    font.letterSpacing: 6
                    opacity: 0.2
                    transform: Scale { xScale: 1.05; yScale: 1.05 }
                }

                Text {
                    id: timeText
                    text: clockContainer.timeStr
                    color: "#c0caf5"
                    font.pointSize: 56 * scaleFactor
                    font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                    font.weight: Font.Bold
                    font.letterSpacing: 6
                    transform: Scale {
                        id: timeScale
                        origin.x: timeText.width / 2
                        origin.y: timeText.height / 2
                        xScale: 1; yScale: 1
                    }

                    ColorAnimation on color {
                        from: "#c0caf5"; to: "#bb9af7"; duration: 8000; loops: Animation.Infinite
                    }

                    SequentialAnimation {
                        id: timePulseAnim
                        ParallelAnimation {
                            NumberAnimation { target: timeScale; property: "xScale"; to: 1.04; duration: 80 }
                            NumberAnimation { target: timeScale; property: "yScale"; to: 1.04; duration: 80 }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: timeScale; property: "xScale"; to: 1.0; duration: 250; easing.type: Easing.OutBack }
                            NumberAnimation { target: timeScale; property: "yScale"; to: 1.0; duration: 250; easing.type: Easing.OutBack }
                        }
                    }
                }
            }

            Text {
                text: clockContainer.dateStr
                color: "#a9b1d6"
                font.pointSize: 18 * scaleFactor
                font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                font.weight: Font.Bold
                font.letterSpacing: 3
                opacity: 0.9
            }

            Text {
                text: clockContainer.dataLoaded
                      ? clockContainer.cityName + " • " + clockContainer.weatherStr + " • " + clockContainer.aqiStr
                      : ""
                color: "#a9b1d6"
                font.pointSize: 18 * scaleFactor
                font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                font.weight: Font.Bold
                font.letterSpacing: 1
                opacity: 0.9
            }

            Text {
                text: isAudioMuted ? "volume_off" : "volume_up"
                color: "#a9b1d6"
                font.pointSize: 18 * scaleFactor
                font.family: "Material Symbols Rounded"
                opacity: 0.9

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.opacity = 1
                    onExited: parent.opacity = 0.9
                    onClicked: isAudioMuted = !isAudioMuted
                }
            }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: !showLogin
        z: 2
        onClicked: {
            if (mouse.button === Qt.RightButton) {
                if (showLogin) hideLogin()
            } else if (!showLogin) {
                showLogin = true
                bgBlur.opacity = 1
                bgBlur.radius = 36
                loginBox.visible = true
                loginAnim.start()
                passwordInput.forceActiveFocus()
            }
        }
    }

    Text {
        id: closeBtn
        text: "✕"
        color: "#c0caf5"
        font.pointSize: 56 * scaleFactor
        font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
        font.weight: Font.Bold
        anchors.top: parent.top
        anchors.topMargin: 40 * scaleFactor
        anchors.right: parent.right
        anchors.rightMargin: 44 * scaleFactor
        z: 200
        visible: showLogin
        opacity: 0.6

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: parent.opacity = 1
            onExited: parent.opacity = 0.6
            onClicked: hideLogin()
        }
    }


    ParallelAnimation {
        id: loginAnim
        NumberAnimation { target: loginBox; property: "scale"; from: 0.8; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        NumberAnimation { target: loginBox; property: "opacity"; from: 0; to: 1; duration: 400 }
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: loginBox; property: "scale"; to: 0.8; duration: 300; easing.type: Easing.InQuad }
        NumberAnimation { target: loginBox; property: "opacity"; to: 0; duration: 250 }
        NumberAnimation { target: bgBlur; property: "opacity"; to: 0; duration: 300 }
        NumberAnimation { target: bgBlur; property: "radius"; to: 0; duration: 300 }
    }

    function hideLogin() {
        showLogin = false
        hideAnim.start()
        closeHideTimer.start()
    }

    Timer {
        id: closeHideTimer
        interval: 350
        onTriggered: {
            loginBox.visible = false
            loginBox.scale = 0.8
            loginBox.opacity = 0
        }
    }

    Item {
        id: loginBox
        anchors.centerIn: parent
        width: 340 * scaleFactor
        height: Math.max(420 * scaleFactor, loginColumn.height + 30 * scaleFactor)
        visible: false
        scale: 0.8
        opacity: 0
        z: 100

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: hideLogin()
        }

        Column {
            id: loginColumn
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: 12 * scaleFactor

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 360 * scaleFactor
                height: 180 * scaleFactor
                z: 2

                Image {
                    width: 360 * scaleFactor
                    height: 180 * scaleFactor
                    source: "welcome.png"
                    fillMode: Image.PreserveAspectFit
                }
            }

            Rectangle {
                id: userPill
                width: parent.width
                height: 44 * scaleFactor
                radius: 22 * scaleFactor
                color: "#24283b"
                border.color: "#3b4261"
                border.width: 1

                property bool popupOpen: false
                property int selectedIndex: 0
                property var users: [
                    { name: "user" },
                    { name: "root" }
                ]
                property string selectedName: users[0].name

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: "👤"
                    color: "#565f89"
                    font.pointSize: 14 * scaleFactor
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 42 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: userPill.selectedName
                    color: "#c0caf5"
                    font.pointSize: 15 * scaleFactor
                    font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▼"
                    color: "#a9b1d6"
                    font.pointSize: 8
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userPill.popupOpen = !userPill.popupOpen
                }
            }

            Rectangle {
                width: parent.width
                height: userPill.popupOpen ? 200 * scaleFactor : 0
                radius: 12 * scaleFactor
                color: "#24283b"
                border.color: "#3b4261"
                border.width: 1
                clip: true
                z: 10

                Behavior on height {
                    NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
                }

                Column {
                    id: userColumn
                    anchors.fill: parent
                    Repeater {
                        model: userPill.users
                        delegate: Item {
                            width: parent.width
                            height: 44 * scaleFactor
                            property bool itemHover: userMa.containsMouse
                            Rectangle {
                                anchors.fill: parent
                                color: index === userPill.selectedIndex ? "#3b4261"
                                     : itemHover ? "#2a2f44" : "transparent"
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 18 * scaleFactor
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                                color: "#c0caf5"
                                font.pointSize: 15 * scaleFactor
                                font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                            }
                            MouseArea {
                                id: userMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    userPill.selectedIndex = index
                                    userPill.selectedName = model.name
                                    userPill.popupOpen = false
                                    passwordInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: passwordBox
                width: parent.width
                height: 44 * scaleFactor
                radius: 22 * scaleFactor
                color: "#24283b"
                border.color: passwordInput.activeFocus ? "#7aa2f7" : "#3b4261"
                border.width: 1

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: "🔒"
                    color: "#565f89"
                    font.pointSize: 14 * scaleFactor
                }

                TextInput {
                    id: passwordInput
                    anchors.left: parent.left
                    anchors.leftMargin: 42 * scaleFactor
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#c0caf5"
                    font.pointSize: 15 * scaleFactor
                    font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                    echoMode: showPwToggle.showPw ? TextInput.Normal : TextInput.Password
                    focus: true

                    property string placeholder: "Password"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 0
                        text: parent.placeholder
                        color: "#565f89"
                        font: parent.font
                        visible: parent.text === "" && !parent.activeFocus
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            console.log("Login: " + userPill.selectedName + " / " + passwordInput.text)
                            event.accepted = true
                        }
                        if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z && event.text.length > 0) {
                            var shiftHeld = event.modifiers & Qt.ShiftModifier
                            capsLockOn = event.text === event.text.toUpperCase() && !shiftHeld
                        }
                    }
                }
            }

            Text {
                text: "⇪ Caps Lock is on"
                color: "#e0af68"
                font.pointSize: 11 * scaleFactor
                font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                anchors.horizontalCenter: parent.horizontalCenter
                visible: capsLockOn && passwordInput.activeFocus
                height: visible ? 20 * scaleFactor : 0
            }

            Item {
                id: showPwToggle
                width: parent.width
                height: 24 * scaleFactor

                property bool showPw: false

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 2 * scaleFactor
                    width: 20 * scaleFactor
                    height: 20 * scaleFactor
                    radius: 10 * scaleFactor
                    color: parent.showPw ? "#7aa2f7" : "transparent"
                    border.color: "#565f89"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: parent.showPw ? "#1a1b26" : "transparent"
                        font.pointSize: 12; font.bold: true
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 28 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Show password"
                    color: "#a9b1d6"
                    font.pointSize: 12 * scaleFactor
                    font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.showPw = !parent.showPw
                }
            }

            Rectangle {
                id: sessionPill
                width: parent.width
                height: 38 * scaleFactor
                radius: 19 * scaleFactor
                color: "#24283b"
                border.color: "#3b4261"
                border.width: 1

                property bool popupOpen: false
                property int currentIndex: 0
                property var sessions: [
                    { name: "niri", file: "niri.desktop" },
                    { name: "plasma", file: "plasma.desktop" }
                ]
                property string currentName: sessions[0].name

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✦"
                    color: "#565f89"
                    font.pointSize: 12 * scaleFactor
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 42 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: sessionPill.currentName
                    color: "#c0caf5"
                    font.pointSize: 13 * scaleFactor
                    font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14 * scaleFactor
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▼"
                    color: "#a9b1d6"
                    font.pointSize: 8
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sessionPill.popupOpen = !sessionPill.popupOpen
                }
            }

            Rectangle {
                width: parent.width
                height: sessionPill.popupOpen ? 200 * scaleFactor : 0
                radius: 12 * scaleFactor
                color: "#24283b"
                border.color: "#3b4261"
                border.width: 1
                clip: true
                z: 10

                Behavior on height {
                    NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
                }

                Column {
                    id: sessionColumn
                    anchors.fill: parent
                    Repeater {
                        model: sessionPill.sessions
                        delegate: Item {
                            width: parent.width
                            height: 38 * scaleFactor
                            property bool itemHover: sessionMa.containsMouse
                            Rectangle {
                                anchors.fill: parent
                                color: index === sessionPill.currentIndex ? "#3b4261"
                                     : itemHover ? "#2a2f44" : "transparent"
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 18 * scaleFactor
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                                color: "#c0caf5"
                                font.pointSize: 13 * scaleFactor
                                font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                            }
                            MouseArea {
                                id: sessionMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sessionPill.currentIndex = index
                                    sessionPill.currentName = model.name
                                    sessionPill.popupOpen = false
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: loginBtn
                width: parent.width
                height: 44 * scaleFactor
                radius: 22 * scaleFactor
                color: loginBtnArea.containsMouse ? "#5d89e8" : "#7aa2f7"

                Text {
                    anchors.centerIn: parent
                    text: "Login"
                    color: "#1a1b26"
                    font.pointSize: 15 * scaleFactor
                    font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: loginBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: console.log("Login: " + userPill.selectedName + " / " + passwordInput.text)
                }
            }

            Row {
                width: parent.width
                height: 36 * scaleFactor
                spacing: 8 * scaleFactor

                Rectangle {
                    width: (parent.width - 16 * scaleFactor) / 3
                    height: 36 * scaleFactor
                    radius: 18 * scaleFactor
                    color: suspendArea.containsMouse ? "#3b4261" : "#24283b"
                    border.color: "#3b4261"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "☾  Suspend"
                        color: "#a9b1d6"
                        font.pointSize: 11 * scaleFactor
                        font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                    }
                    MouseArea {
                        id: suspendArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hideLogin()
                    }
                }

                Rectangle {
                    width: (parent.width - 16 * scaleFactor) / 3
                    height: 36 * scaleFactor
                    radius: 18 * scaleFactor
                    color: rebootArea.containsMouse ? "#f7768e" : "#24283b"
                    border.color: rebootArea.containsMouse ? "#f7768e" : "#3b4261"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↻  Reboot"
                        color: rebootArea.containsMouse ? "#1a1b26" : "#a9b1d6"
                        font.pointSize: 11 * scaleFactor
                        font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                    }
                    MouseArea {
                        id: rebootArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: console.log("Reboot")
                    }
                }

                Rectangle {
                    width: (parent.width - 16 * scaleFactor) / 3
                    height: 36 * scaleFactor
                    radius: 18 * scaleFactor
                    color: shutdownArea.containsMouse ? "#db4b4b" : "#24283b"
                    border.color: shutdownArea.containsMouse ? "#db4b4b" : "#3b4261"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⏻  Shutdown"
                        color: shutdownArea.containsMouse ? "#1a1b26" : "#a9b1d6"
                        font.pointSize: 11 * scaleFactor
                        font.family: "M PLUS Rounded 1c", "Noto Sans JP", "sans-serif"
                    }
                    MouseArea {
                        id: shutdownArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: console.log("Shutdown")
                    }
                }
            }
        }
    }
}
