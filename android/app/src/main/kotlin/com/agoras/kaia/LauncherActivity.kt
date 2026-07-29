package com.agoras.kaia

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.*


class LauncherActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Opcional: Aquí puedes poner una pantalla de carga nativa
        // setContentView(R.layout.tu_pantalla_de_carga)

        iniciarVerificacionIntegridad()
    }

    private fun iniciarVerificacionIntegridad() {
        val isDebug = (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if(isDebug){
            val intent = Intent(this, MainActivity::class.java)
            if (this.intent.data != null) {
                intent.action = Intent.ACTION_VIEW
                intent.data = this.intent.data
            }
            startActivity(intent)
            finish()
            return
        }

        // 1. El "nonce" idealmente debe generarlo tu servidor de backend
        // para evitar ataques de repetición (replay attacks).

        val integrityManager = IntegrityManagerFactory.create(this)
        val nonce = (1..32).map { "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".random() }.joinToString("")

        val request = IntegrityTokenRequest.builder()
            .setCloudProjectNumber(56790361943L)
            .setNonce(nonce)
            .build()


        integrityManager.requestIntegrityToken(request)
            .addOnSuccessListener { response ->
                val token = response.token()
                // 2. Enviar el token a tu servidor para desencriptarlo
                verificarTokenConElServidor(token)
            }
            .addOnFailureListener { e ->
                mostrarErrorYCerrar("Fallo de Play Integrity: ${e.message}")
            }
    }

    private fun verificarTokenConElServidor(token: String) {
        // ⚠️ IMPORTANTE: Aquí debes hacer tu petición HTTP POST (ej. con OkHttp)
        // a tu backend pasándole el 'token'. Esto debe correr en un hilo secundario.

        // Simulamos el resultado del servidor:
        var dispositivoSeguro: Boolean = false

        val client = OkHttpClient()


        val request = Request.Builder().url("https://api.agoras.es/verifyintegrity").header("platform", "android")
            .header("integritytoken", token).build()


        val response = client.newCall(request).execute()

        if (response.code == 200) {
            dispositivoSeguro = true
        }else if(response.code == 403){
            dispositivoSeguro = false
        }

        if (dispositivoSeguro) {
            // 3. ¡El dispositivo es íntegro! Arrancamos Flutter.
            val intent = Intent(this, MainActivity::class.java)
            if (this.intent.data != null) {
                intent.action = Intent.ACTION_VIEW
                intent.data = this.intent.data
            }
            startActivity(intent)
            finish() // Destruimos esta actividad para que el usuario no pueda volver atrás
        } else {
            mostrarErrorYCerrar("El dispositivo no pasó las pruebas de seguridad.")
        }
    }

    private fun mostrarErrorYCerrar(mensaje: String) {
        Toast.makeText(this, mensaje, Toast.LENGTH_LONG).show()
        finish() // Cierra la aplicación
    }
}