package com.example.bloqueador_chamadas

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.telecom.TelecomManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bloqueador_chamadas/call_blocker"
    private val REQUEST_CODE_SET_DEFAULT_DIALER = 101
    private val REQUEST_CODE_CALL_SCREENING_ROLE = 102
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enableCallScreening") {
                Log.d(TAG, "enableCallScreening method called")
                requestRole()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestRole() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                if (!roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                    startActivityForResult(intent, REQUEST_CODE_CALL_SCREENING_ROLE)
                } else {
                    Log.d(TAG, "Role CALL_SCREENING is already held")
                }
            } else {
                Log.d(TAG, "Role CALL_SCREENING is not available")
                requestDefaultDialerRole()
            }
        } else {
            requestDefaultDialerRole()
        }
    }

    private fun requestDefaultDialerRole() {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        if (packageName != telecomManager.defaultDialerPackage) {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
            intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            startActivityForResult(intent, REQUEST_CODE_SET_DEFAULT_DIALER)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_CALL_SCREENING_ROLE) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d(TAG, "App is now the default call screening app")
            } else {
                Log.d(TAG, "App is not the default call screening app")
            }
        } else if (requestCode == REQUEST_CODE_SET_DEFAULT_DIALER) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d(TAG, "App is now the default dialer")
            } else {
                Log.d(TAG, "App is not the default dialer")
            }
        }
    }
}
