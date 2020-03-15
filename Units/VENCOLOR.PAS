(*********************************************************************)
(* Programmname    : VENCOLOR.PAS V1.6               	             	*)
(* Programmautor   : Michael Rippl             		                	*)
(* Compiler        : Quick Pascal V1.0    	                        *)
(* Inhalt          : Farbenverwaltung des Kopierprogramms Venus V2.1 *)
(* Bemerkung       : -                                         	 	*)
(* Letzte énderung : 01-Mar-1991                               	 	*)
(*********************************************************************)

UNIT VenColor;

INTERFACE

USES Primitiv;													(* Units einbinden			*)

VAR cBlack,                								(* Farbe Schwarz				*)
	 cBlue, 														(* Farbe Blau					*)
	 cCyan,                                         (* Farbe Cyan					*)
	 cRed,                                          (* Farbe Rot					*)
	 cMagenta,                                      (* Farbe Magenta				*)
	 cLightGrey,                                    (* Farbe Hell-Grau	  		*)
	 cLightGreen,                                   (* Farbe Hell-GrÅn			*)
	 cLightCyan,                                    (* Farbe Hell-Cyan 			*)
	 cYellow,                                       (* Farbe Gelb					*)
	 cWhite,  													(* Farbe Wei·					*)
	 cLightRed,													(* Farbe Hell-Rot				*)
	 cLightMagenta : Colors;                        (* Farbe Hell-Magenta		*)

(* Diese Prozedur setzt die Farben fÅr eine Farbgrafikkarte *)
PROCEDURE SetColorGraphics;

(* Diese Prozedur setzt die Farben fÅr eine Monochromgrafikkarte *)
PROCEDURE SetMonochromGraphics;

(* Diese Prozedur modifiziert die Farbpalette *)
PROCEDURE ModifyColors(VAR ColBlack, ColBlue, ColCyan, ColRed, ColMag,
							  ColLiGrey, ColLiGrn, ColLiCyan, ColYel, ColWh,
							  ColLiRed, ColLiMag : Colors);

IMPLEMENTATION

(* Diese Prozedur setzt die Farben fÅr eine Farbgrafikkarte *)
PROCEDURE SetColorGraphics;
BEGIN
	 cBlack := Black;											(* Farbwerte eintragen		*)
	 cBlue := Blue;
	 cCyan := Cyan;
	 cRed := Red;
	 cMagenta := Magenta;
	 cLightGrey := LightGrey;
	 cLightGreen := LightGreen;
	 cLightCyan := LightCyan;
	 cYellow := Yellow;
	 cWhite := White;
	 cLightRed := LightRed;
	 cLightMagenta := LightMagenta;
END; (* SetColorGraphics *)

(* Diese Prozedur setzt die Farben fÅr eine Monochromgrafikkarte *)
PROCEDURE SetMonochromGraphics;
BEGIN
	 cBlack := Black;											(* Farbwerte eintragen		*)
	 cBlue := Black;
	 cCyan := LightGrey;
	 cRed := LightGrey;
	 cMagenta := LightGrey;
	 cLightGrey := LightGrey;
	 cLightGreen := White;
	 cLightCyan := White;
	 cYellow := White;
	 cWhite := White;
	 cLightRed := White;
	 cLightMagenta := White;
END; (* SetMonochromGraphics *)

(* Diese Prozedur modifiziert die Farbpalette *)
PROCEDURE ModifyColors(VAR ColBlack, ColBlue, ColCyan, ColRed, ColMag,
							  ColLiGrey, ColLiGrn, ColLiCyan, ColYel, ColWh,
							  ColLiRed, ColLiMag : Colors);
BEGIN
	 cBlack := ColBlack;	  									(* Farbwerte verÑndern		*)
	 cBlue := ColBlue;
	 cCyan := ColCyan;
	 cRed := ColRed;
	 cMagenta := ColMag;
	 cLightGrey := ColLiGrey;
	 cLightGreen := ColLiGrn;
	 cLightCyan := ColLiCyan;
	 cYellow := ColYel;
	 cWhite := ColWh;
	 cLightRed := ColLiRed;
	 cLightMagenta := ColLiMag;
END; (* ModifyColors *)

END. (* VenColor *)
