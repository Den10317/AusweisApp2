/*
 * \copyright Copyright (c) 2015-2020 Governikus GmbH & Co. KG, Germany
 */

import QtQuick 2.10
import QtQuick.Layouts 1.3

import Governikus.Global 1.0
import Governikus.RemoteServiceView 1.0
import Governikus.TechnologyInfo 1.0
import Governikus.Type.ApplicationModel 1.0
import Governikus.Type.SettingsModel 1.0
import Governikus.Type.RemoteServiceModel 1.0
import Governikus.Type.ReaderPlugIn 1.0
import Governikus.Type.NumberModel 1.0


Item {
	id: baseItem
	signal requestPluginType(int pReaderPlugInType)

	property bool settingsPushed: remoteServiceSettings.visible
	property bool wifiEnabled: ApplicationModel.wifiEnabled
	property bool foundSelectedReader: ApplicationModel.availableReader > 0

	Connections {
		target: ApplicationModel
		onFireCertificateRemoved: {
			//: INFO ANDROID IOS The paired smartphone was removed since it did not respond to connection attempts. It needs to be paired again before using it.
			ApplicationModel.showFeedback(qsTr("The device %1 was unpaired because it did not react to connection attempts. Pair the device again to use it as a card reader.").arg(pDeviceName))
		}
	}

	onFoundSelectedReaderChanged: {
		if (baseItem.settingsPushed && foundSelectedReader) {
			remoteServiceSettings.firePop()
		}
	}

	ProgressIndicator {
		id: progressIndicator
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.right: parent.right
		height: parent.height / 2
		imageIconSource: "qrc:///images/icon_remote.svg"
		imagePhoneSource: "qrc:///images/phone_remote.svg"
		state: foundSelectedReader ? "two" : "off"
	}

	TechnologyInfo {
		id: techInfo
		anchors.left: parent.left
		anchors.leftMargin: 5
		anchors.right: parent.right
		anchors.rightMargin: anchors.leftMargin
		anchors.top: progressIndicator.bottom
		anchors.bottom: switchToNfcAction.top

		enableButtonVisible: !wifiEnabled || !foundSelectedReader
		enableButtonText: {
			SettingsModel.translationTrigger

			if (!wifiEnabled) {
				//: LABEL ANDROID IOS
				return qsTr("Enable WiFi");
			} else if (!foundSelectedReader) {
				//: LABEL ANDROID IOS
				return qsTr("Pair device");
			} else {
				//: LABEL ANDROID IOS
				return qsTr("Continue")
			}
		}

		onEnableClicked: {
			if (!wifiEnabled) {
				ApplicationModel.enableWifi()
			} else if (!baseItem.settingsPushed) {
				firePush(remoteServiceSettings)
			}
		}
		enableText: {
			SettingsModel.translationTrigger

			if (!wifiEnabled) {
				//: INFO ANDROID IOS The WiFi module needs to be enabled in the system settings to use the remote service.
				return qsTr("To use the remote service WiFi has to be activated. Please activate WiFi in your device settings.");
			} else if (!foundSelectedReader) {
				//: INFO ANDROID IOS No paired and reachable device was found, hint that the remote device needs to be actually started for this feature.
				return qsTr("No paired smartphone as card reader (SaC) with activated \"remote service\" available.");
			} else {
				return "";
			}
		}

		titleText: (foundSelectedReader ?
			//: LABEL ANDROID IOS
			qsTr("Determine card") :
			//: LABEL ANDROID IOS
			qsTr("Establish connection")
		) + SettingsModel.translationTrigger

		subTitleText: {
			SettingsModel.translationTrigger

			if (!visible) {
				return "";
			} else if (!!NumberModel.inputError) {
				return NumberModel.inputError;
			} else if (ApplicationModel.extendedLengthApdusUnsupported) {
				//: INFO ANDROID IOS The device does not support Extended Length and can not be used as card reader.
				qsTr("The connected smartphone as card reader (SaC) unfortunately does not meet the technical requirements (Extended Length not supported).");
			} else if (NumberModel.pinDeactivated) {
				//: INFO ANDROID IOS The online authentication is disabled and needs to be enabled by the authorities.
				return qsTr("The online identification function of your ID card is not activated. Please contact your responsible authority to activate the online identification function.");
			} else {
				//: INFO ANDROID IOS The connection to the smartphone was established, the ID card may be inserted.
				return qsTr("Connected to %1. Please place the NFC interface of the smartphone on your ID card.").arg(RemoteServiceModel.connectedServerDeviceNames);
			}
		}
	}

	TechnologySwitch {
		id: switchToNfcAction
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		selectedTechnology: ReaderPlugIn.REMOTE
		onRequestPluginType: parent.requestPluginType(pReaderPlugInType)
	}

	RemoteServiceSettings {
		id: remoteServiceSettings
		visible: false
	}
}
