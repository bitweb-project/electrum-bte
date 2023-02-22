import QtQuick 2.6
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.0
import QtQuick.Controls.Material.impl 2.12

import QtQml 2.6
import QtMultimedia 5.6

import org.electrum_bte 1.0

import "controls"

ApplicationWindow
{
    id: app

    visible: false // initial value

    // dimensions ignored on android
    width: 480
    height: 800

    Material.theme: Material.Dark
    Material.primary: Material.Indigo
    Material.accent: Material.LightBlue
    font.pixelSize: constants.fontSizeMedium

    property Item constants: appconstants
    Constants { id: appconstants }

    property alias stack: mainStackView

    property variant activeDialogs: []

    property bool _wantClose: false
    property var _exceptionDialog

    header: ToolBar {
        id: toolbar

        background: Rectangle {
            implicitHeight: 48
            color: Material.dialogColor

            layer.enabled: true
            layer.effect: ElevationEffect {
                elevation: 4
                fullWidth: true
            }
        }

        ColumnLayout {
            spacing: 0
            width: parent.width
            height: toolbar.height

            RowLayout {
                id: toolbarTopLayout

                Layout.fillWidth: true
                Layout.rightMargin: constants.paddingMedium
                Layout.alignment: Qt.AlignVCenter

                Item {
                    Layout.preferredWidth: constants.paddingXLarge
                    Layout.preferredHeight: 1
                }

                Image {
                    visible: Daemon.currentWallet
                    source: '../../icons/wallet.png'
                    Layout.preferredWidth: constants.iconSizeSmall
                    Layout.preferredHeight: constants.iconSizeSmall
                }

                Label {
                    Layout.preferredHeight: Math.max(implicitHeight, toolbarTopLayout.height)
                    text: stack.currentItem.title
                    elide: Label.ElideRight
                    // horizontalAlignment: Qt.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    font.pixelSize: constants.fontSizeMedium
                    font.bold: true
                    MouseArea {
                        height: toolbarTopLayout.height
                        anchors.fill: parent
                        onClicked: {
                            if (stack.currentItem.objectName != 'Wallets')
                                stack.pushOnRoot(Qt.resolvedUrl('Wallets.qml'))
                        }
                    }
                }

                Item {
                    visible: Network.isTestNet
                    width: column.width
                    height: column.height

                    ColumnLayout {
                        id: column
                        spacing: 0
                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: constants.iconSizeSmall
                            Layout.preferredHeight: constants.iconSizeSmall
                            source: "../../icons/info.png"
                        }

                        Label {
                            id: networkNameLabel
                            text: Network.networkName
                            color: Material.accentColor
                            font.pixelSize: constants.fontSizeXSmall
                        }
                    }
                }

                Image {
                    Layout.preferredWidth: constants.iconSizeSmall
                    Layout.preferredHeight: constants.iconSizeSmall
                    visible: Daemon.currentWallet && Daemon.currentWallet.isWatchOnly
                    source: '../../icons/eye1.png'
                    scale: 1.5
                }

                LightningNetworkStatusIndicator {
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (stack.currentItem.objectName != 'NetworkOverview')
                                stack.push(Qt.resolvedUrl('NetworkOverview.qml'))
                        }
                    }
                }

                OnchainNetworkStatusIndicator {
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (stack.currentItem.objectName != 'NetworkOverview')
                                stack.push(Qt.resolvedUrl('NetworkOverview.qml'))
                        }
                    }
                }
            }

            WalletSummary {
                id: walletSummary
                Layout.preferredWidth: app.width
            }
        }
    }

    StackView {
        id: mainStackView
        anchors.fill: parent

        initialItem: Qt.resolvedUrl('WalletMainView.qml')

        function getRoot() {
            return mainStackView.get(0)
        }
        function pushOnRoot(item) {
            if (mainStackView.depth > 1) {
                mainStackView.replace(mainStackView.get(1), item)
            } else {
                mainStackView.push(item)
            }
        }
    }

    Timer {
        id: coverTimer
        interval: 10
        onTriggered: {
            app.visible = true
            cover.opacity = 0
        }
    }

    Rectangle {
        id: cover
        parent: Overlay.overlay
        anchors.fill: parent

        z: 1000
        color: 'black'

        Behavior on opacity {
            enabled: AppController ? AppController.isAndroid() : false
            NumberAnimation {
                duration: 1000
                easing.type: Easing.OutQuad;
            }
        }
    }

    property alias newWalletWizard: _newWalletWizard
    Component {
        id: _newWalletWizard
        NewWalletWizard {
            parent: Overlay.overlay
            Overlay.modal: Rectangle {
                color: "#aa000000"
            }
        }
    }

    property alias serverConnectWizard: _serverConnectWizard
    Component {
        id: _serverConnectWizard
        ServerConnectWizard {
            parent: Overlay.overlay
            Overlay.modal: Rectangle {
                color: "#aa000000"
            }
        }
    }

    property alias messageDialog: _messageDialog
    Component {
        id: _messageDialog
        MessageDialog {
            onClosed: destroy()
        }
    }

    property alias passwordDialog: _passwordDialog
    Component {
        id: _passwordDialog
        PasswordDialog {
            onClosed: destroy()
        }
    }

    property alias pinDialog: _pinDialog
    Component {
        id: _pinDialog
        Pin {
            onClosed: destroy()
        }
    }

    property alias genericShareDialog: _genericShareDialog
    Component {
        id: _genericShareDialog
        GenericShareDialog {
            onClosed: destroy()
        }
    }

    property alias openWalletDialog: _openWalletDialog
    Component {
        id: _openWalletDialog
        OpenWalletDialog {
            onClosed: destroy()
        }
    }

    property alias channelOpenProgressDialog: _channelOpenProgressDialog
    ChannelOpenProgressDialog {
        id: _channelOpenProgressDialog
    }

    NotificationPopup {
        id: notificationPopup
        width: parent.width
    }

    Component {
        id: crashDialog
        ExceptionDialog {
            z: 1000
        }
    }

    property alias swaphelper: _swaphelper
    Component {
        id: _swaphelper
        SwapHelper {
            id: __swaphelper
            wallet: Daemon.currentWallet
            onConfirm: {
                var dialog = app.messageDialog.createObject(app, {text: message, yesno: true})
                dialog.yesClicked.connect(function() {
                    dialog.close()
                    __swaphelper.executeSwap(true)
                })
                dialog.open()
            }
            onAuthRequired: {
                app.handleAuthRequired(__swaphelper, method)
            }
            onError: {
                var dialog = app.messageDialog.createObject(app, { text: message })
                dialog.open()
            }
        }
    }

    Component.onCompleted: {
        coverTimer.start()

        if (!Config.autoConnectDefined) {
            var dialog = serverConnectWizard.createObject(app)
            // without completed serverConnectWizard we can't start
            dialog.rejected.connect(function() {
                app.visible = false
                Qt.callLater(Qt.quit)
            })
            dialog.accepted.connect(function() {
                var newww = app.newWalletWizard.createObject(app)
                newww.walletCreated.connect(function() {
                    Daemon.availableWallets.reload()
                    // and load the new wallet
                    Daemon.load_wallet(newww.path, newww.wizard_data['password'])
                })
                newww.open()
            })
            dialog.open()
        } else {
            if (Daemon.availableWallets.rowCount() > 0) {
                Daemon.load_wallet()
            } else {
                var newww = app.newWalletWizard.createObject(app)
                newww.walletCreated.connect(function() {
                    Daemon.availableWallets.reload()
                    // and load the new wallet
                    Daemon.load_wallet(newww.path, newww.wizard_data['password'])
                })
                newww.open()
            }
        }
    }

    onClosing: {
        if (activeDialogs.length > 0) {
            var activeDialog = activeDialogs[activeDialogs.length - 1]
            if (activeDialog.allowClose) {
                activeDialog.doClose()
            } else {
                console.log('dialog disallowed close')
            }
            close.accepted = false
            return
        }
        if (stack.depth > 1) {
            close.accepted = false
            stack.pop()
        } else {
            // destroy most GUI components so that we don't dump so many null reference warnings on exit
            if (app._wantClose) {
                app.header.visible = false
                mainStackView.clear()
            } else {
                var dialog = app.messageDialog.createObject(app, {
                    text: qsTr('Close Electrum?'),
                    yesno: true
                })
                dialog.yesClicked.connect(function() {
                    dialog.close()
                    app._wantClose = true
                    app.close()
                })
                dialog.open()
                close.accepted = false
            }
        }
    }

    Connections {
        target: Daemon
        function onWalletRequiresPassword(name, path) {
            console.log('wallet requires password')
            var dialog = openWalletDialog.createObject(app, { path: path, name: name })
            dialog.open()
        }
        function onWalletOpenError(error) {
            console.log('wallet open error')
            var dialog = app.messageDialog.createObject(app, {'text': error})
            dialog.open()
        }
        function onAuthRequired(method) {
            handleAuthRequired(Daemon, method)
        }
    }

    Connections {
        target: AppController
        function onUserNotify(wallet_name, message) {
            notificationPopup.show(wallet_name, message)
        }
        function onShowException(crash_data) {
            if (app._exceptionDialog)
                return
            app._exceptionDialog = crashDialog.createObject(app, {
                crashData: crash_data
            })
            app._exceptionDialog.onClosed.connect(function() {
                app._exceptionDialog = null
            })
            app._exceptionDialog.open()
        }
    }

    Connections {
        target: Daemon.currentWallet
        function onAuthRequired(method) {
            handleAuthRequired(Daemon.currentWallet, method)
        }
        // TODO: add to notification queue instead of barging through
        function onPaymentSucceeded(key) {
            notificationPopup.show(Daemon.currentWallet.name, qsTr('Payment Succeeded'))
        }
        function onPaymentFailed(key, reason) {
            notificationPopup.show(Daemon.currentWallet.name, qsTr('Payment Failed') + ': ' + reason)
        }
    }

    Connections {
        target: Config
        function onAuthRequired(method) {
            handleAuthRequired(Config, method)
        }
    }

    function handleAuthRequired(qtobject, method) {
        console.log('auth using method ' + method)
        if (method == 'wallet') {
            if (Daemon.currentWallet.verify_password('')) {
                // wallet has no password
                qtobject.authProceed()
            } else {
                var dialog = app.passwordDialog.createObject(app, {'title': qsTr('Enter current password')})
                dialog.accepted.connect(function() {
                    if (Daemon.currentWallet.verify_password(dialog.password)) {
                        qtobject.authProceed()
                    } else {
                        qtobject.authCancel()
                    }
                })
                dialog.rejected.connect(function() {
                    qtobject.authCancel()
                })
                dialog.open()
            }
        } else if (method == 'pin') {
            if (Config.pinCode == '') {
                // no PIN configured
                qtobject.authProceed()
            } else {
                var dialog = app.pinDialog.createObject(app, {mode: 'check', pincode: Config.pinCode})
                dialog.accepted.connect(function() {
                    qtobject.authProceed()
                    dialog.close()
                })
                dialog.rejected.connect(function() {
                    qtobject.authCancel()
                })
                dialog.open()
            }
        } else {
            console.log('unknown auth method ' + method)
            qtobject.authCancel()
        }
    }

    property var _lastActive: 0 // record time of last activity
    property int _maxInactive: 30 // seconds
    property bool _lockDialogShown: false

    onActiveChanged: {
        console.log('app active = ' + active)
        if (!active) {
            // deactivated
            _lastActive = Date.now()
        } else {
            // activated
            if (_lastActive != 0 && Date.now() - _lastActive > _maxInactive * 1000) {
                if (_lockDialogShown || Config.pinCode == '')
                    return
                var dialog = app.pinDialog.createObject(app, {mode: 'check', canCancel: false, pincode: Config.pinCode})
                dialog.accepted.connect(function() {
                    dialog.close()
                    _lockDialogShown = false
                })
                dialog.open()
                _lockDialogShown = true
            }
        }
    }

}
