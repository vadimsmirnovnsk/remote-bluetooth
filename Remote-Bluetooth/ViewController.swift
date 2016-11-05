import UIKit
import SnapKit

class ViewController: UIViewController {

	@IBOutlet var zoomStepper: UIStepper!
	@IBOutlet var recordStartButton: UIButton!
	@IBOutlet var recordStopButton: UIButton!
	@IBOutlet var whiteBalanceSlider: UISlider!

	private let remoteController = RemoteController()

	override func viewDidLoad() {
		super.viewDidLoad()

		configureControls()
	}

	private func configureControls() {
		zoomStepper.minimumValue = 1.0
		zoomStepper.maximumValue = 10.0
		zoomStepper.stepValue = 0.2
		zoomStepper.value = 1.0

		whiteBalanceSlider.minimumValue = 3000.0
		whiteBalanceSlider.maximumValue = 7000.0
		whiteBalanceSlider.value = 5400.0
	}

	@IBAction func didChangeZoomValue(_ sender: UIStepper) {
		print(sender.value)
		remoteController.setZoom(withLevel: sender.value)
	}

	@IBAction func didChangeWhiteBalanceValue(_ sender: UISlider) {
		remoteController.setWhiteBalance(withTemperature: Int(sender.value))
	}

	@IBAction func didTapRecordStartButton(_ sender: UIButton) {
		remoteController.takeVideoStart()
	}

	@IBAction func didTapRecordStopButton(_ sender: UIButton) {
		remoteController.takeVideoStop()
	}


}

