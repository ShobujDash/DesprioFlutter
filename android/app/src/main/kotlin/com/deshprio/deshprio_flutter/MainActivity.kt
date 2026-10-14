package com.deshprio.deshprio_flutter

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import java.util.UUID
import kotlin.concurrent.thread
import kotlin.math.ceil

class MainActivity : FlutterActivity() {
    private val channelName = "deshprio/printer"
    private val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pairedDevices" -> {
                    ensureBluetoothPermission()
                    result.success(pairedDevices())
                }
                "printReceipt" -> {
                    val address = call.argument<String>("address")
                    val receipt = call.argument<Map<String, Any?>>("receipt")
                    if (address.isNullOrBlank() || receipt == null) {
                        result.error("BAD_ARGS", "Printer address or receipt missing", null)
                        return@setMethodCallHandler
                    }
                    thread {
                        try {
                            printReceipt(address, receipt)
                            runOnUiThread { result.success(null) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("PRINT_FAILED", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureBluetoothPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.BLUETOOTH_CONNECT), 2001)
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun pairedDevices(): List<Map<String, String>> {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
        ) {
            return emptyList()
        }
        return adapter.bondedDevices.map {
            mapOf("name" to (it.name ?: "Bluetooth Printer"), "address" to it.address)
        }
    }

    @SuppressLint("MissingPermission")
    private fun printReceipt(address: String, receipt: Map<String, Any?>) {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: error("Bluetooth পাওয়া যায়নি")
        if (!adapter.isEnabled) error("Bluetooth চালু করুন")
        val device: BluetoothDevice = adapter.getRemoteDevice(address)
        val bytes = escposRaster(buildReceiptBitmap(receipt))
        adapter.cancelDiscovery()
        device.createRfcommSocketToServiceRecord(sppUuid).use { socket ->
            socket.connect()
            val out = socket.outputStream
            var index = 0
            while (index < bytes.size) {
                val end = minOf(index + 512, bytes.size)
                out.write(bytes, index, end - index)
                out.flush()
                Thread.sleep(25)
                index = end
            }
        }
    }

    private fun buildReceiptBitmap(receipt: Map<String, Any?>): Bitmap {
        val width = 384
        val margin = 16
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textSize = 25f
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
        }
        val titlePaint = TextPaint(paint).apply {
            textSize = 30f
            typeface = Typeface.create("sans-serif", Typeface.BOLD)
        }
        val boldPaint = TextPaint(paint).apply {
            typeface = Typeface.create("sans-serif", Typeface.BOLD)
        }

        val lines = mutableListOf<Pair<String, TextPaint>>()
        lines += "দেশপ্রিয় মিষ্টান্ন ভাণ্ডার" to titlePaint
        receipt["storeName"]?.toString()?.takeIf { it.isNotBlank() }?.let {
            lines += "দোকান: $it" to paint
        }
        lines += "তারিখ: ${bnDate()}" to paint
        lines += "--------------------------------" to paint

        @Suppress("UNCHECKED_CAST")
        val items = receipt["items"] as? List<Map<String, Any?>> ?: emptyList()
        items.forEachIndexed { index, item ->
            lines += "${index + 1}. ${item["itemName"]?.toString() ?: ""}" to paint
            lines += "${numText(item["quantity"])} কেজি x ৳${numText(item["pricePerKg"])}    ৳${numText(item["totalPrice"])}" to paint
        }

        val totalAmount = number(receipt["totalAmount"])
        val paidAmount = number(receipt["paidAmount"])
        lines += "--------------------------------" to paint
        lines += "মোট: ৳${numText(totalAmount)}" to boldPaint
        lines += "জমা: ৳${numText(paidAmount)}" to paint
        lines += "বাকি: ৳${numText(totalAmount - paidAmount)}" to boldPaint
        lines += "ধন্যবাদ!" to titlePaint

        var height = margin
        val layouts = lines.map { (text, p) ->
            val layout = StaticLayout.Builder
                .obtain(text, 0, text.length, p, width - margin * 2)
                .setAlignment(Layout.Alignment.ALIGN_CENTER)
                .setLineSpacing(2f, 1f)
                .setIncludePad(true)
                .build()
            height += layout.height + 6
            layout
        }

        val bitmap = Bitmap.createBitmap(width, height + margin + 48, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        var y = margin
        layouts.forEach { layout ->
            canvas.save()
            canvas.translate(margin.toFloat(), y.toFloat())
            layout.draw(canvas)
            canvas.restore()
            y += layout.height + 6
        }
        return bitmap
    }

    private fun escposRaster(bitmap: Bitmap): ByteArray {
        val widthBytes = ceil(bitmap.width / 8.0).toInt()
        val imageBytes = ByteArrayOutputStream()
        for (y in 0 until bitmap.height) {
            for (xByte in 0 until widthBytes) {
                var b = 0
                for (bit in 0..7) {
                    val x = xByte * 8 + bit
                    if (x < bitmap.width) {
                        val pixel = bitmap.getPixel(x, y)
                        val avg = (Color.red(pixel) + Color.green(pixel) + Color.blue(pixel)) / 3
                        if (avg < 180) b = b or (0x80 shr bit)
                    }
                }
                imageBytes.write(b)
            }
        }

        val out = ByteArrayOutputStream()
        out.write(byteArrayOf(0x1B, 0x40))
        out.write(byteArrayOf(0x1D, 0x76, 0x30, 0x00))
        out.write(byteArrayOf((widthBytes and 0xff).toByte(), ((widthBytes shr 8) and 0xff).toByte()))
        out.write(byteArrayOf((bitmap.height and 0xff).toByte(), ((bitmap.height shr 8) and 0xff).toByte()))
        out.write(imageBytes.toByteArray())
        out.write(byteArrayOf(0x0A, 0x0A, 0x0A))
        return out.toByteArray()
    }

    private fun number(value: Any?): Double {
        return when (value) {
            is Number -> value.toDouble()
            else -> value?.toString()?.toDoubleOrNull() ?: 0.0
        }
    }

    private fun numText(value: Any?): String {
        val n = number(value)
        return if (n % 1.0 == 0.0) n.toInt().toString() else n.toString()
    }

    private fun bnDate(): String {
        val cal = Calendar.getInstance()
        return "${cal.get(Calendar.DAY_OF_MONTH)}/${cal.get(Calendar.MONTH) + 1}/${cal.get(Calendar.YEAR)}"
    }
}
