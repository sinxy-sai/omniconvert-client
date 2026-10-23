package site.sinxysai.omniconvert

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val channelName = "site.sinxysai.omniconvert/updates"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method != "installVerifiedApk") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val path = call.argument<String>("path") ?: error("APK path is required")
                val expected = call.argument<String>("sha256")?.lowercase() ?: error("SHA-256 is required")
                installVerifiedApk(path, expected)
                result.success(null)
            } catch (error: Exception) {
                result.error("INSTALL_FAILED", error.message, null)
            }
        }
    }

    private fun installVerifiedApk(path: String, expectedSha256: String) {
        val apk = File(path).canonicalFile
        val privateRoot = filesDir.canonicalFile
        require(apk.path.startsWith(File(privateRoot, "updates").canonicalPath + File.separator)) { "APK must be in private updates storage" }
        require(apk.isFile) { "APK does not exist" }
        require(sha256(apk) == expectedSha256) { "APK SHA-256 mismatch" }
        val archive = packageManager.getPackageArchiveInfo(apk.path, PackageManager.GET_SIGNING_CERTIFICATES)
            ?: error("Invalid APK")
        require(archive.packageName == packageName) { "APK package name mismatch" }
        val current = packageManager.packageInfo(packageName)
        val archiveSigners = archive.signingInfo?.apkContentsSigners ?: error("APK has no signing certificate")
        val currentSigners = current.signingInfo?.apkContentsSigners ?: error("Installed app has no signing certificate")
        require(archiveSigners.contentEquals(currentSigners)) { "APK signing certificate mismatch" }
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", apk)
        startActivity(Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        })
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(8192)
            var count = input.read(buffer)
            while (count > 0) { digest.update(buffer, 0, count); count = input.read(buffer) }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private fun PackageManager.packageInfo(name: String) = if (Build.VERSION.SDK_INT >= 33) {
        getPackageInfo(name, PackageManager.PackageInfoFlags.of(PackageManager.GET_SIGNING_CERTIFICATES.toLong()))
    } else {
        @Suppress("DEPRECATION") getPackageInfo(name, PackageManager.GET_SIGNING_CERTIFICATES)
    }
}
