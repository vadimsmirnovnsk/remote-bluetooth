class RemoteController {

	private let peripheral = BluetoothPeripheral()

	init() {
		peripheral.startAdvertising()
	}

	deinit {
		peripheral.stopAdvertising()
	}

	func takePhoto() {
		let eventString = RemoteControls.takePhotoId + RemoteControls.divider + RemoteEvents.didTap
		send(eventString)
	}

	func takeVideoStart() {
		let eventString = RemoteControls.takeVideoId + RemoteControls.divider + RemoteEvents.didTap
		send(eventString)
	}

	func takeVideoStop() {
		let eventString = RemoteControls.takeVideoId + RemoteControls.divider + RemoteEvents.didRelease
		send(eventString)
	}

	func setWhiteBalance(withTemperature temperature: Int) {
		guard temperature >= 3200 && temperature <= 7000 else { return }

		let eventString = RemoteControls.whiteBalanceId + RemoteControls.divider + String(temperature)
		send(eventString)
	}

	func setZoom(withLevel level: Double) {
		let eventString = RemoteControls.zoomControl + RemoteControls.divider + String(level)
		send(eventString)
	}

	private func send(_ string: String) {
		let dataToSend = string.data(using: String.Encoding.utf8)
		if let dataToSend = dataToSend {
			peripheral.send(dataToSend)
		}
	}

}
