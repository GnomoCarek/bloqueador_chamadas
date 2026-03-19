package com.example.bloqueador_chamadas

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.Q)
class MyCallScreeningService : CallScreeningService() {

    private val TAG = "MyCallScreeningService"

    @SuppressLint("NewApi")
    override fun onScreenCall(callDetails: Call.Details) {
        Log.d(TAG, "onScreenCall: Incoming call detected")
        
        // Check if blocking is enabled in SharedPreferences
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
        val isBlockingEnabled = prefs.getBoolean("flutter.isBlockingEnabled", false)
        
        if (!isBlockingEnabled) {
            Log.d(TAG, "onScreenCall: Blocking is disabled by user. Allowing call.")
            allowCall(callDetails)
            return
        }

        val handle = callDetails.handle
        if (handle == null) {
            Log.d(TAG, "onScreenCall: Handle is null (Private number). Blocking.")
            blockCall(callDetails)
            return
        }

        val phoneNumber = handle.schemeSpecificPart ?: ""
        Log.d(TAG, "onScreenCall: Phone number is $phoneNumber")

        if (phoneNumber.isBlank()) {
            Log.d(TAG, "onScreenCall: Phone number is blank. Blocking.")
            blockCall(callDetails)
            return
        }

        val isInContacts = isNumberInContacts(applicationContext.contentResolver, phoneNumber)
        Log.d(TAG, "onScreenCall: Is number in contacts? $isInContacts")

        if (isInContacts) {
            Log.d(TAG, "onScreenCall: Number found in contacts. Allowing call.")
            allowCall(callDetails)
        } else {
            Log.d(TAG, "onScreenCall: Number not in contacts. Blocking call.")
            blockCall(callDetails)
        }
    }

    private fun blockCall(callDetails: Call.Details) {
        val response = CallResponse.Builder()
            .setDisallowCall(true)
            .setRejectCall(true)
            .setSilenceCall(true)
            .setSkipCallLog(true)
            .setSkipNotification(true)
            .build()
        respondToCall(callDetails, response)
        Log.d(TAG, "blockCall: Call blocked and silenced")

        // Increment blocked calls counter
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
        val currentCount = prefs.getInt("flutter.blockedCallsCount", 0)
        prefs.edit().putInt("flutter.blockedCallsCount", currentCount + 1).apply()
    }

    private fun allowCall(callDetails: Call.Details) {
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSilenceCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        respondToCall(callDetails, response)
        Log.d(TAG, "allowCall: Call allowed")
    }

    private fun isNumberInContacts(contentResolver: ContentResolver, phoneNumber: String): Boolean {
        // Basic normalization: remove spaces, dashes, etc. but keep +
        val normalizedNumber = phoneNumber.replace(Regex("[^0-9+]"), "")
        
        if (normalizedNumber.isBlank()) {
            return false
        }

        // Try PhoneLookup first (standard way)
        val lookupUri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(normalizedNumber))
        val projection = arrayOf(ContactsContract.PhoneLookup._ID, ContactsContract.PhoneLookup.DISPLAY_NAME)
        
        try {
            contentResolver.query(lookupUri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val contactName = cursor.getString(cursor.getColumnIndexOrDefault(ContactsContract.PhoneLookup.DISPLAY_NAME, "Unknown"))
                    Log.d(TAG, "isNumberInContacts: Found contact: $contactName")
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "isNumberInContacts: Error querying contacts", e)
        }

        // Fallback: search in common data kinds if PhoneLookup fails (some devices have issues with PhoneLookup)
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val selection = "${ContactsContract.CommonDataKinds.Phone.NUMBER} = ? OR ${ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER} = ?"
        val selectionArgs = arrayOf(normalizedNumber, normalizedNumber)
        
        try {
            contentResolver.query(uri, arrayOf(ContactsContract.CommonDataKinds.Phone.CONTACT_ID), selection, selectionArgs, null)?.use { cursor ->
                if (cursor.count > 0) {
                    Log.d(TAG, "isNumberInContacts: Found number in CommonDataKinds.Phone fallback")
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "isNumberInContacts: Error in fallback query", e)
        }

        return false
    }

    // Helper extension to handle missing columns safely
    private fun android.database.Cursor.getColumnIndexOrDefault(columnName: String, defaultValue: String): Int {
        val index = getColumnIndex(columnName)
        return if (index >= 0) index else -1
    }
}
