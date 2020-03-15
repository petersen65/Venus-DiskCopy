(*********************************************************************)
(* Programmname    : AVAIL.PAS V1.3   	                         		*)
(* Programmautor   : Michael Rippl                              		*)
(* Compiler        : Quick Pascal V1.0                          		*)
(* Inhalt          : Anzeigen der Speicher-Ressourcen eines Rechners *)
(* Bemerkung       : -                                          		*)
(* Letzte Žnderung : 08-Nov-1990                                		*)
(*********************************************************************)

PROGRAM Avail;             								(*$M 8192, 0, 655360			*)

USES Expanded, Extended, HiMem, SysInfo;	 			(* Units einbinden			*)

VAR ExtMemSizeLow,											(* Low Byte aus CMos 		*)
	 ExtMemSizeHigh : BYTE;									(* High Byte aus CMos		*)
	 XmsLargest,												(* Gr”áter XMS Block			*)
	 XmsTotal		 : WORD;									(* Freier XMS Speicher		*)

BEGIN
	WriteLn('Memory Avail  Version 1.3  Copyright (c) 1990 by Michael Rippl');
	WriteLn;
	WriteLn('   Dos Memory Installed : ', MainMemSize : 13, ' Bytes');
	WriteLn('   Dos Memory Available : ', MemAvail + 16768 : 13, ' Bytes');
	WriteLn;

	IF (ParamStr(1) = '/x') OR (ParamStr(1) = '/X') THEN
	BEGIN
		InitXms;

		IF XmsMemAvail THEN
		BEGIN
			QueryFreeXms(XmsLargest, XmsTotal);

			Write('   Xms Memory Largest   : ', LONGINT(XmsLargest) * 1024 : 13);
			WriteLn(' Bytes');
			Write('   Xms Memory Available : ', LONGINT(XmsTotal) * 1024 : 13);
			WriteLn(' Bytes');
			WriteLn;
		END
		ELSE
		BEGIN
			WriteLn('   Xms Memory Largest   :             0 Bytes');
			WriteLn('   Xms Memory Available :             0 Bytes');
			WriteLn;
		END;
	END;

	IF EmsMemAvail THEN
	BEGIN
		Write('   Expanded Memory Installed : ');
		WriteLn((LONGINT(EmsNrOfPages) * 16384) : 8, ' Bytes');
		Write('   Expanded Memory Available : ');
		WriteLn(LONGINT(NrOfAvailablePages) * 16384 : 8, ' Bytes');
	END
	ELSE
	BEGIN
		WriteLn('   Expanded Memory Installed :        0 Bytes');
		WriteLn('   Expanded Memory Available :        0 Bytes');
	END;

	ReadCMos($17, ExtMemSizeLow);
	ReadCMos($18, ExtMemSizeHigh);

	WriteLn;
	Write('   Extended Memory Installed : ');
	Write((LONGINT(ExtMemSizeLow) + 256 * LONGINT(ExtMemSizeHigh)) * 1024 : 8);
	WriteLn(' Bytes');
	Write('   Extended Memory Available : ', LONGINT(ExtMemSize) * 1024 : 8);
	WriteLn(' Bytes');
END. (* Avail *)
