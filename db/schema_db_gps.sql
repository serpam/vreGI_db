BEGIN TRANSACTION;
DROP TABLE IF EXISTS "dicc_ganaderos";
CREATE TABLE IF NOT EXISTS "dicc_ganaderos" (
	"id_ganadero",
	"user_name",
	"localidad",
	PRIMARY KEY("id_ganadero")
);
DROP TABLE IF EXISTS "dicc_explotaciones";
CREATE TABLE IF NOT EXISTS "dicc_explotaciones" (
	"id_ganadero",
	"name_ganadero",
	"id_explotacion",
	"size",
	"obs",
	FOREIGN KEY("id_ganadero") REFERENCES "dicc_ganaderos"("id_ganadero")
);
DROP TABLE IF EXISTS "dicc_dispositivos";
CREATE TABLE IF NOT EXISTS "dicc_dispositivos" (
	"id",
	"id_ganadero",
	"type",
	"codigo_gps",
	"user_name",
	"animal",
	FOREIGN KEY("id_ganadero") REFERENCES "dicc_ganaderos"("id_ganadero"),
	PRIMARY KEY("codigo_gps")
);
DROP TABLE IF EXISTS "datos_gps";
CREATE TABLE IF NOT EXISTS "datos_gps" (
	"id"	INTEGER,
	"codigo_gps",
	"lat",
	"lng",
	"time_stamp"	DATETIME,
	FOREIGN KEY("codigo_gps") REFERENCES "dicc_dispositivos"("codigo_gps"),
	PRIMARY KEY("id" AUTOINCREMENT)
);
COMMIT;
