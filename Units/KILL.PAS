program kill;

uses dos, disk;

var dr : string;

procedure killtrack(drive : char; secs : byte);
var regs : registers;
	 k : byte;
VAR FormatBuffer    : ARRAY [1..20] OF
								 CylFormat;	  					(* Puffer fÅr Spurdaten		*)
begin
	SetDiskFormat(Drive, 2);
	SetDriveInfo(BytesPerSector512, secs, 1);

	FOR k := 1 TO secs DO									(* Formatpuffer ausfÅllen	*)
	BEGIN
		WITH FormatBuffer[k] DO
		BEGIN
			NrOfCyl := 0;								(* Zylinder ist konstant 	*)
			NrOfSide := 0;									(* Seite ist konstant		*)
			NrOfSector := k;									(* Sektoren nummerieren	 	*)
			BytesPerSector := BytesPerSector512;		(* 512 Bytes pro Sektor		*)
		END;
	END;

	Regs.AH := $05;							
	Regs.DL := Ord(drive) - Ord('A');
	Regs.DH := 0;	(* seite *)
	Regs.CH := 0;  (* cylinder *)
	Regs.AL := secs;	(* sektoren pro spur *)
	Regs.ES := seg(FormatBuffer);
	Regs.BX := ofs(FormatBuffer);
	Intr($13, Regs);
end;

begin
	dr := paramstr(1);

	if paramcount = 0 then
		killtrack('A', 3)
	else killtrack(upcase(dr[1]), 3);
end.
