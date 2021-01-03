// ***** Protocolo CPU esclava ***** (sin problemas, creo)
// (c) 2020-2021 Carlos J. Santisteban
char cmd;  // memoria compartida

void cpu_principal(void)
{
     // antes del comando...
     while (cmd);  // espera a que la esclava esté libre
     // escribir parámetros
     cmd = COMANDO_DESEADO;
     // hacer otras cosas...
     while (cmd);  // rendez-vous (si es preciso)
     // después...
}

void cpu_esclava(void)
{
     // tareas de inicialización
     cmd = 0;  // lista para su uso
     while (-1)  // bucle infinito...
     {
           while (!cmd);  // espera orden
           // ejecutarla...
           cmd = 0;
     }
}

// ***** Rutina de Servicio de Interrupción *****

char via[16];  // registros VIA 65(c)22 en $DF80
int pos_pbuf;  // puntero a registro paralelo
int max_pbuf;  // limite buffer paralelo??
int min_pbuf;  // inicio buffer paralelo??

void isr(void)
{
     char a, b;
     
     salvar_registros();  // en la pila
     a = via[VIA_IS];  // fuente de interrupción
     bit(a);  // ***** leer documentación VIA *****
     if (negative)  // bit 7
     {
     }
     if (overflow)  // bit 6
     {
     }
     if (a & 0x20)  // bit 5
     {
     }
     // ...
 // if PA... muy prioritario, revisar mucho ¿lee_pbuf?
       b = via[VIA_PA];  // dato PA
       *pos_pbuf = b;
       pos_pbuf++;
       if (pos_pbuf >= max_pbuf)
       {
         lock_pa();  // off-line
         pbuf_full();  // ????? obtiene nueva min_pbuf
         pos_pbuf = min_pbuf;
         unlock_pa();  // on-line
       }
 // if UART...
       // descargar FIFO del 16c550; consultar docs.
 // if TIMER_A...
       leer_UART();  // ?????
       cambio();

}

// ***** Cambio de trenza *****

char trenza_actual;  // registro de conmutación $DFB4

void cambio(void)
{
     char x;
     
     salvar_estado();  // no en la pila, sino en p.cero (incluye SP)
     // ¿Qué pasa con el 65c816? ¿dejar 2 bytes/reg de sitio?
     x = trenza_actual;  // lee registro conmutación
     trenza_actual = 0;  // cambio temporal a supertrenza
     do
     {
         x++;
         if ( x > MAX_TRENZA )  x = 1;  // da la vuelta (wrap)
     }
     while ( trenza[x] != ACTIVA );  // lista en p.cero de la supertrenza
     // ¿¿llamar aquí demonio??
     trenza_actual = x;  // cambia registro a nueva trenza
     restaurar_estado();  // recupera estado de la nueva trenza ¿65c816?
     RTI();  // ¿es la última? Habría que corregir pila en llamada voluntaria
}

