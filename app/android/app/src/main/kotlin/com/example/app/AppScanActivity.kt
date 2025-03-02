package com.example.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import com.zynksoftware.documentscanner.ScanActivity
import com.zynksoftware.documentscanner.model.DocumentScannerErrorModel
import com.zynksoftware.documentscanner.model.ScannerResults
import java.io.File

class AppScanActivity: ScanActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.app_scan_activity_layout)
        addFragmentContentLayout()
    }

    override fun onClose() {
        finish()
    }

    override fun onError(error: DocumentScannerErrorModel) {
        when (error.errorMessage) {
            DocumentScannerErrorModel.ErrorMessage.TAKE_IMAGE_FROM_GALLERY_ERROR -> {
                val text = R.string.errorLoadingImage
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()
            }
            DocumentScannerErrorModel.ErrorMessage.PHOTO_CAPTURE_FAILED -> {
                val text = R.string.errorCapturePhoto
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()

                setResult(RESULT_CANCELED)
                finish()
            }
            DocumentScannerErrorModel.ErrorMessage.CAMERA_USE_CASE_BINDING_FAILED -> {
                val text = R.string.errorCamera
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()
            }
            DocumentScannerErrorModel.ErrorMessage.DETECT_LARGEST_QUADRILATERAL_FAILED -> {
                val text = R.string.errorOccurred
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()

                setResult(RESULT_CANCELED)
                finish()
            }
            DocumentScannerErrorModel.ErrorMessage.INVALID_IMAGE -> {
                val text = R.string.errorInvalidImage
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()
            }
            DocumentScannerErrorModel.ErrorMessage.CAMERA_PERMISSION_REFUSED_WITHOUT_NEVER_ASK_AGAIN -> {
                val text = R.string.errorCameraRefused
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()
            }
            DocumentScannerErrorModel.ErrorMessage.CAMERA_PERMISSION_REFUSED_GO_TO_SETTINGS -> {
                val text = R.string.errorCameraPermaRefused
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()
            }
            DocumentScannerErrorModel.ErrorMessage.STORAGE_PERMISSION_REFUSED_WITHOUT_NEVER_ASK_AGAIN -> {
                val text = R.string.errorStorageRefused
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()
            }
            DocumentScannerErrorModel.ErrorMessage.STORAGE_PERMISSION_REFUSED_GO_TO_SETTINGS -> {
                val text = R.string.errorStoragePermaRefused
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()
            }
            DocumentScannerErrorModel.ErrorMessage.CROPPING_FAILED -> {
                val text = R.string.errorCroppingFailed
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()

                setResult(RESULT_CANCELED)
                finish()
            }
            null -> {
                val text = R.string.errorOccurred
                val duration = Toast.LENGTH_SHORT

                val toast = Toast.makeText(this, text, duration)
                toast.show()

                setResult(RESULT_CANCELED)
                finish()
            }
        }
    }

    override fun onSuccess(scannerResults: ScannerResults) {
        val file: File? = scannerResults.croppedImageFile

        if (file != null) {
            val uri = Uri.fromFile(file)

            val intent = Intent()
            intent.setData(uri)

            setResult(RESULT_OK, intent)

            finish()
        } else {
            setResult(RESULT_CANCELED)
            finish()
        }
    }

}