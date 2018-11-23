#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../ftdi/ftd2xx.h"

#define SUCCEEDED			0
#define	ERR_ARGC			1
#define	ERR_LIST_DEVICE		2
#define	ERR_NO_DEVICE		3
#define	ERR_CBUS_BITBANG	4

// memory for storing parameters
char Manufacturer[32];
char ManufacturerId[64];
char Description[64];
char SerialNumber[16];

int main(int argc, char* argv[])
{
	FT_STATUS ftStatus;
	FT_HANDLE hFt;
	static FT_PROGRAM_DATA Data;
	DWORD numDevs = 0;
	DWORD testDev;
	int ret=SUCCEEDED;

	// check number of args
	if(argc != 2)
	{
		ret = ERR_ARGC;
		printf("%d\n",ret);
		return ret;
	}
	// get number of devices
	ftStatus = FT_ListDevices(&numDevs,NULL,FT_LIST_NUMBER_ONLY);
	if(ftStatus != FT_OK) {
		printf("%d\n",ERR_LIST_DEVICE);
		return ret;
	} 
	// connect memory 
	Data.Manufacturer = Manufacturer; /* E.g "FTDI" */
	Data.ManufacturerId = ManufacturerId; /* E.g. "FT" */
	Data.Description = Description; /* E.g. "USB HS Serial Converter" */
	Data.SerialNumber = SerialNumber; /* E.g. "FT000001" if fixed, or NULL */

	// get Manufacture and description
	for (testDev = 0;testDev < numDevs; testDev++) {
		ftStatus = FT_Open(testDev, &hFt);
		if(ftStatus != FT_OK) {
			continue;
		}
		Data.Signature1 = 0x00000000;
		Data.Signature2 = 0xffffffff;
		ftStatus = FT_EE_Read(hFt,&Data);
		if(ftStatus != FT_OK) {
			FT_Close(hFt);
			continue;
		}
		/*
		printf("Manufacture = %s\n",Data.Manufacturer);
		printf("ManufactureId = %s\n",Data.ManufacturerId);
		printf("Description = %s\n",Data.Description);
		printf("SerialNumber = %s\n",Data.SerialNumber);
		*/

		// check Description
		if(strncmp(Data.Description,argv[1],sizeof(Description)) == 0) break;
		FT_Close(hFt);
	}
	 // error check
	if(testDev>= numDevs)
	{
		ret = ERR_NO_DEVICE;
		printf("%d\n",ERR_NO_DEVICE);
		return ret;
	}

	// change to CBUS_BITBANG and reset LSI
	ftStatus = FT_SetBitMode(hFt, 0xF0 , FT_BITMODE_CBUS_BITBANG);
	if(ftStatus != FT_OK) {
		printf("%d\n",ERR_CBUS_BITBANG);
		goto error;
	} 

	// set test pin of ML620Q504H to high
	ftStatus = FT_SetBitMode(hFt, 0xF2 , FT_BITMODE_CBUS_BITBANG);
	if(ftStatus != FT_OK) {
		ret = ERR_CBUS_BITBANG;
		goto error;
	} 

	// start ML620Q504H as boot mode
	ftStatus = FT_SetBitMode(hFt, 0xC0 , FT_BITMODE_CBUS_BITBANG);
	if(ftStatus != FT_OK) {
		ret = ERR_CBUS_BITBANG;
		goto error;
	}

error:
	FT_Close(hFt);
	//printf("%d\n",ret);
	return ret;
}

