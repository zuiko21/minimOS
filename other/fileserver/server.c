/* emulación de servidor de archivos para minimOS
 * v0.5b1
 * (c) 2015-2020 Carlos J. Santisteban
 * modificado 20150202-1438 */

#include <stdio.h>
#include <string.h>

void to_hex(long x, char* c)
{
	int i;
	char h[16] = "0123456789ABCDEF";
	
	for (i=3; i>=0; i--)
	{
		c[i] = h[x % 16];
		x >>= 4;
	}
	c[4] = '\0';
}

int main(void)
{
	float speed;
	char buffer[80], user[80], byt;
	char* pos;
	int log, link, ack;
	long i, siz;
	FILE *arch, *sal, *entr;
	
	sal = fopen("output.txt", "wb");	// salida serie, para depuración
	entr = stdin;
//	entr = fopen("input.txt", "rb");	// entrada serie, para depuración
	if (entr == NULL)	// hubo problemas
	{
		printf("***NO HAY CONEXIÓN DE ENTRADA***\n");
		return -1;
	}
	if (sal == NULL)	// hubo problemas
	{
		printf("***PROBLEMA CON LA CONEXIÓN DE SALIDA***\n");
		return -1;
	}
	printf("*** Servidor de archivos para minimOS, v0.5b1 ***\n");
	printf("(pulsar CONTROL + C para salir)\n");
	while (-1)
	{
		link = 0;
		printf("Esperando conexión...");
		while (!link)	// recibir 'U' y el speedcode
		{
			byt = fgetc(entr);
			if (byt == 0x55)	// 'U' recibida
			{
				link = 1;		// enlace posible
				byt = fgetc(entr);		// lee speedcode
				speed = byt/16.0;		// convierte a coma flotante, $10 = 1 MHz
			}
		}
		fputs("\"\xFF\0", sal);			// enviar confirmación enlace, soy muy rápido
		printf(" conectado a %f MHz\n", speed);
		fgets(buffer, 80, entr);
//printf("[%s]",buffer);//DEBUG
		log = 0;
		if (buffer[0] == '!')			// comando de login
		{
			pos = strchr(buffer+1, ':');			// busca separador contraseña
			if (pos == NULL)
				pos = buffer + strlen(buffer)-1;	// sin contraseña
			strncpy(user, buffer+1, pos-buffer-1);	// copia sólo ID
			user[pos-buffer-1] = '\0';			// TERMINA CADENA
			log = 1;							// login OK
			fputc('A', sal);					// reconocer login
			printf(" Usuario: %s (OK)\n", user);
		}
		while (log)		// mientras no deshaga la conexión
		{
			byt = fgetc(entr);				// lee comando
			switch(byt)
			{
				case 'L':					// LOAD
					fgets(buffer, 80, entr);	// obtiene nombre de archivo
					buffer[strlen(buffer)-1] = '\0';	// elimina LF
//printf("[%s]",buffer);//DEBUG
					printf(" >Solicita archivo %s ", buffer);
					arch = fopen(buffer, "rb");		// abrir archivo
					if (arch == NULL)				// no existe
					{
						printf("*** NO EXISTE ***\n");
						fputc('x', sal);			// enviar 'x'
					}
					else
					{
						fseek(arch, 0, SEEK_END);	// medir archivo
						siz = ftell(arch);
						buffer[0] = '$';			// inciar cadena hex
						to_hex(siz, buffer+1);		// convertir
						fputs(buffer, sal);			// enviar tamaño
						fputc('\n', sal);
						printf("(%ld bytes)...", siz);
						ack = 1;
						while ((byt = fgetc(entr)) !='A')	// esperar ACK
						{
							if (byt == 'x')			// rechazó archivo
							{
								ack = 0;
								break;
							}
						}
						if (ack)
						{
							printf(" aceptado.\n");
							fseek(arch, 0, SEEK_SET);
							for (i=0; i<siz; i++)
							{
								fputc(fgetc(arch), sal);
								printf("\rEnviando byte %ld...", i);
							}
							printf(" OK\n");
						}
						else
						{
							printf("RECHAZADO.\n");
						}
					}
					break;
				case 'S':						// SAVE
					fgets(buffer, 80, entr);	// obtiene nombre de archivo
//printf("[%s]",buffer);//DEBUG
					printf(" >Prentende SUBIR archivo %s ", buffer);
					fgets(buffer, 80, entr);	// obtiene longitud (para descartarla)
//printf("[%s]",buffer);//DEBUG
					buffer[strlen(buffer)-1] = '\0';			// TERMINA CADENA
					printf("(%s) ** NO IMPLEMENTADO **\n", buffer);
					fputc('x', sal);			// rechaza operación
					break;
				case '.':						// LOGOUT
					printf("<Usuario %s desconectado>\n", user);
					log = 0;
					break;
				case 'A':						// ACK
					printf("ACK???\n");
/*				default:
					fgets(buffer, 80, entr);	// rechaza resto de cadena
printf("[[[[%s]]]]",buffer);//DEBUG
					fputc('x', sal);			// rechaza operación
*/			}
		}
		fflush(sal);
	}
	
	return 0;
}
