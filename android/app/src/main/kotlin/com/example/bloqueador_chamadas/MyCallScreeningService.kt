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
        Log.d(TAG, "onScreenCall: Received a call")
        val phoneNumber = callDetails.handle.schemeSpecificPart
        Log.d(TAG, "onScreenCall: Phone number is $phoneNumber")

        val shouldBlock = !isNumberInContacts(applicationContext.contentResolver, phoneNumber)
        Log.d(TAG, "onScreenCall: Should block call? $shouldBlock")

        val response = CallResponse.Builder()
            .setDisallowCall(shouldBlock)
            .setRejectCall(shouldBlock)
            .setSkipCallLog(shouldBlock)
            .setSkipNotification(shouldBlock)
            .build()
        
        respondToCall(callDetails, response)
    }

    private fun isNumberInContacts(contentResolver: ContentResolver, phoneNumber: String): Boolean {
        if (phoneNumber.isBlank()) {
            return false
        }
        val lookupUri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
        val projection = arrayOf(ContactsContract.PhoneLookup._ID)
        
        val cursor = contentResolver.query(lookupUri, projection, null, null, null)
        cursor.use {
            if (it != null && it.moveToFirst()) {
                Log.d(TAG, "isNumberInContacts: Number $phoneNumber found in contacts.")
                return true
            }
        }
        Log.d(TAG, "isNumberInContacts: Number $phoneNumber not found in contacts.")
        return false
    }
}
