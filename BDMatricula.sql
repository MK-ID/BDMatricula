use master
GO

if exists(select name from sysdatabases where name in('DBMATRICULA_DS'))
	drop database DBMATRICULA_DS
go
------------------------------------------------------------------------------------------------------------
--Creacion de base de datos
Create Database DBMATRICULA_DS
go
---creacion de tablas
use DBMatricula_DS
go

If Object_ID (N'TUbigeo', N'U') IS NOT NULL 
	DROP TABLE TUbigeo
go
CREATE TABLE TUbigeo
(
	CodUbigeo varchar(6) not null,
	CodDepartamento varchar(2) not NULL,
	CodProvincia varchar(2) not NULL,
	CodDistrito varchar(2) not NULL,
	NomDepartamento varchar(100) not null,
	NomProvincia varchar(100) not null,
	NomDistrito varchar(100) not null,
	PRIMARY KEY (CodUbigeo)
)

If Object_ID (N'TEscuela', N'U') IS NOT NULL 
DROP TABLE TEscuela
go
Create table TEscuela
(
	CodEscuela varchar(3),
	Nombre varchar(70),
	CodFacultad varchar(5),
	NomFacultad varchar(90),
	primary key(CodEscuela)

)
go

If Object_ID (N'TDocente', N'U') IS NOT NULL 
DROP TABLE TDocente
go

Create table TDocente
(
CodDocente varchar(6),---codigo de identificacion de docente
Nombres     varchar(40),
FecNacimiento date,
IndSexo varchar(1),
Especialidad varchar(100),
NroDocIdentidad varchar(15),
Nacionalidad varchar(25),
CodDepAcademico varchar(4),
NomDepAcademico varchar(60)
primary key (CodDocente),
)
go

If Object_ID (N'TAlumno', N'U') IS NOT NULL 
DROP TABLE TAlumno
go

Create table TAlumno
(
CodAlumno varchar(12),
ApePaterno varchar(50),
ApeMaterno varchar(50),
Nombres varchar(50),
Sexo varchar(1),
FecNacimiento date,
LugNacimiento varchar(6),
NumDocIdentidad varchar(15),
Nacionalidad varchar(25),
Telefono varchar(15),
Dirección varchar(80),
CodEscuela varchar(3),
primary key(CodAlumno),
foreign key (CodEscuela) references TEscuela(CodEscuela)
)
go
select * from TAlumno
If Object_ID (N'TCurso', N'U') IS NOT NULL 
DROP TABLE TCurso
go

CREATE TABLE [dbo].[TCurso]
(
CodCurso varchar(6) NOT NULL,
NomCurso varchar(80) NULL,
Categoria varchar(4) NULL,
NroCreditos int NULL,
PreRequisito varchar(6) NULL,
HorPracticas int NULL,
HorTeoricas int NULL,
Ciclo varchar (10) NULL,
CodEscuela varchar(3) NULL,
primary key (CodCurso),
foreign key (CodEscuela) references TEscuela(CodEscuela)
)
GO

If Object_ID (N'TCarAcademica', N'U') IS NOT NULL 
DROP TABLE TCarAcademica
go

CREATE TABLE TCarAcademica
(
	CodCarga int NOT NULL,
	CodDocente varchar(6) NOT NULL,
	CodCurso varchar(6) NOT NULL,
	SemAcademico varchar(8) NOT NULL,
	primary key (CodCarga),
	foreign key (CodDocente) references TDocente (CodDocente),
	foreign key (CodCurso) references TCurso (CodCurso)
	)
	GO

If Object_ID (N'TMatricula', N'U') IS NOT NULL 
DROP TABLE TMatricula
go 

CREATE TABLE TMatricula
(
	NroMatricula int NOT NULL,
	CodAlumno varchar(12) NOT NULL,
	CodCarga int,
	SemAcademico varchar(8) NOT NULL,
	FecMatricula date NOT NULL,
	Nota int NULL,
	primary key (NroMatricula),
	foreign key (CodAlumno) references TAlumno (CodAlumno),
	foreign key (CodCarga) references TCarAcademica (CodCarga)
)
GO

If Object_ID (N'TNotas', N'U') IS NOT NULL 
DROP TABLE TNotas
go 

CREATE TABLE TNotas
(
	NroReg int NOT NULL,
	NroMatricula int NOT NULL,
	Unidad varchar(3) NOT NULL,
	NotaUnidad int NOT NULL,
	primary key (NroReg),
	foreign key (NroMatricula) references TMatricula(NroMatricula)
	);
GO