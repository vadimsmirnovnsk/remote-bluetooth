import CoreBluetooth
import Synchronized

class BluetoothPeripheral: NSObject {

	fileprivate var peripheralManager: CBPeripheralManager?
	fileprivate var transferCharacteristic: CBMutableCharacteristic?

	fileprivate var dataArray = [Data]()

	// First up, check if we're meant to be sending an EOM
	fileprivate var dataToSend: Data?
	fileprivate var sendingEOM = false
	fileprivate var sendDataIndex = 0

	override init() {
		super.init()

		peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
	}

	func startAdvertising() {
		peripheralManager!.startAdvertising([
			CBAdvertisementDataServiceUUIDsKey : [transferServiceUUID],
			CBAdvertisementDataLocalNameKey : "Remote Control",
		])
	}

	func stopAdvertising() {
		peripheralManager?.stopAdvertising()
	}

}

extension BluetoothPeripheral { // Send Data

	func send(_ data: Data) {
		synchronized(object: self, closure: {
			self.dataArray.append(data)
			sendDataIndex = 0
			dataToSend = data
		})

		privateSend()
	}

	/** Sends the next amount of data to the connected central */
	fileprivate func privateSend() {
		guard !sendingEOM else { return sendEOM() }

		// We're not sending an EOM, so we're sending data

		// Is there any left to send? // No data left.  Do nothing
		guard let dataToSend = dataToSend else { return }
		guard sendDataIndex < dataToSend.count else { return }

		// There's data left, so send until the callback fails, or we're done.
		var didSend = true

		// Send with chunks
		while didSend {
			// Work out how big it should be // Can't be longer than 20 bytes
			let amountToSend = min(dataToSend.count - sendDataIndex, NOTIFY_MTU)

			let nsdataToSend = dataToSend as NSData
			// Copy out the data we want
			let chunk = NSData(
				bytes: nsdataToSend.bytes + sendDataIndex,
				length: amountToSend
			)

			// Send it
			didSend = peripheralManager!.updateValue(
				chunk as Data,
				for: transferCharacteristic!,
				onSubscribedCentrals: nil
			)

			// If it didn't work, drop out and wait for the callback
			if (!didSend) { return }

			let stringFromData = NSString(
				data: chunk as Data,
				encoding: String.Encoding.utf8.rawValue
			)!
			print("Sent: \(stringFromData)")

			// It did send, so update our index
			sendDataIndex += amountToSend;

			// Was it the last one?
			if (sendDataIndex >= dataToSend.count) {
				// Set this so if the send fails, we'll send it next time
				sendingEOM = true
				sendEOM()

				synchronized(object: self, closure: {
					self.dataToSend = self.dataArray.removeFirst()
					sendDataIndex = 0
				})

			}
		}
	}

	private func sendEOM() {
		// send it
		let didSend = peripheralManager?.updateValue(
			"EOM".data(using: String.Encoding.utf8)!,
			for: transferCharacteristic!,
			onSubscribedCentrals: nil
		)

		// Did it send?
		if (didSend == true) {

			// It did, so mark it as sent
			sendingEOM = false

			print("Sent: EOM")
		}

		// It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
		return
	}

}

extension BluetoothPeripheral: CBPeripheralManagerDelegate {

	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		print(">>> DID UPDATE STATE \(peripheral.state)")
		guard peripheral.state == .poweredOn else { return }

		// Start with the CBMutableCharacteristic
		transferCharacteristic = CBMutableCharacteristic(
			type: transferCharacteristicUUID,
			properties: .notify,
			value: nil,
			permissions: .readable
		)

		// Then the service
		let transferService = CBMutableService(
			type: transferServiceUUID,
			primary: true
		)

		// Add the characteristic to the service
		transferService.characteristics = [transferCharacteristic!]

		// And add it to the peripheral manager
		peripheralManager?.add(transferService)
		
		print(">>> Peripheral powered on: \(peripheral)")
	}

	func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
		print(">>> DID START ADVERTISING WITH ERROR \(error)")
	}

	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
		print(">>> DID SUBSCRIBE CENTRAL\(central)")
	}

	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
		print(">>> DID UNSUBSCRIBE CENTRAL \(central)")
	}

	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
		print(">>> DID RECEIVE READ REQUESTS: \(request)")
	}

	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
		print(">>> DID RECEIVE WRITE REQUESTS: \(requests)")
	}

	func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {

		self.startAdvertising()
		print(">>> DID ADD SERVICE: \(service) with error: \(error)")
	}

	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
		print(">>> READY FOR UPDATE SUBSCRIBERS \(peripheral)")

		privateSend()
	}

}
