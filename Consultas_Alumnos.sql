/*
Autor: Luis Mikhail Palomino Paucar
Fecha: 01/09/21
Vistas y procedimientos almacenados para alumnos
TODO: Implementar los procedimientos almacenados de agregar, editar, elimiinar y busacar
*/
USE master
go

use DBMATRICULA_DS
go

--procedimiento almacenado para sacar el promedio de un alumno
IF OBJECT_ID('usp_ActualizarNota') is not null
    DROP PROCEDURE usp_ActualizarNota
go
CREATE PROCEDURE usp_ActualizarNota
AS
BEGIN
    Declare @Nota1 int
	Declare @Nota2 int
	Declare @Nota3 int
	Declare @Promedio int
	Declare @i int
	Declare @TotalRegistros int
	Declare @NroMatricula int
	Declare @CodAlumno varchar(12)
	Declare @CodCarga int
	Declare @Tabla table
	(
	    NroMatricula int,
		codCarga varchar(10),
		CodAlumno varchar(12)
	)
    BEGIN TRANSACTION TransActualizar
    BEGIN TRY
        insert into @Tabla
        select NroMatricula,CodCarga,codAlumno from TMatricula
        set @i=1
        set @TotalRegistros= (select count(*) from TMatricula)
        While (@i<= @TotalRegistros)
        Begin
            set @NroMatricula=(select max(NroMatricula) from @Tabla)	
            set @codAlumno =(select codAlumno from TMatricula where NroMatricula=@NroMatricula)
            set @CodCarga =(select CodCarga from TMatricula where NroMatricula=@NroMatricula) 
            set @Nota1= (select NotaUnidad from TNotas 
                        where [NroMatricula]=@NroMatricula and Unidad=1)
            set @Nota2=(select NotaUnidad from TNotas where [NroMatricula]=@NroMatricula and Unidad=2)
            set @Nota3=(select NotaUnidad from TNotas where [NroMatricula]=@NroMatricula and Unidad=3)
            set @Promedio =(@Nota1+@Nota2*2+@Nota3*2)/5
            --actualizar matricula
            update TMatricula
            set Nota=@Promedio
            where NroMatricula=@NroMatricula
            and CodCarga = @CodCarga
            and CodAlumno= @CodAlumno
            ---eliminamos la matricula utiliza
            delete from @Tabla where NroMatricula=@NroMatricula
            set @i= @i+1
        END
    COMMIT TRANSACTION TransActualizar
        SELECT CodError = 0, Mensaje = 'Transacción ejecutada correctamente'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION TransActualizar
        SELECT CodError = 1, Mensaje = 'Error, la transacción no se ejecutó'
    END CATCH
END
GO
EXECUTE usp_ActualizarNota
GO
--verificación de los promedios de cada alumno
select * from TMatricula
GO
--ALTER table para cambiar la columna de Nota por Promedio

--vista alumnos
IF OBJECT_ID('vAlumnos') is not null
    DROP view vAlumnos
go
Create view vAlumnos
as
    Select CodAlumno, ApePaterno +' '+ApeMaterno+' '+Nombres as Alumno,
	Sexo,Year(FecNacimiento) as AñoNacimiento,
	(Year(GetDate())-Year(FecNacimiento)) as Edad,
	LugNacimiento, U.NomDepartamento,U.NomProvincia,U.NomDistrito,
	Nacionalidad,A.CodEscuela,E.Nombre as Escuela,NomFacultad
	from TEscuela E inner join TAlumno A
	on (E.codEscuela=A.CodEscuela)
	left OUTER join TUbigeo U
	on (A.LugNacimiento=U.CodUbigeo);
GO
--consulta de vista alumnos
SELECT * from vAlumnos
go

--vista alumnos
IF OBJECT_ID('VNotas') is not null
    DROP view VNotas
go
CREATE view vNotas
AS
    SELECT * from TNotas
GO

--consulta cantidad de mujeres y varones, representados por %
SELECT Sexo, COUNT(*) as Cantidad from vAlumnos
GROUP BY Sexo

--lugar de nacimiento, esto disgrega mucho los datos
select LugNacimiento, NomDepartamento,COUNT(*) as cantidad  from vAlumnos
GROUP by LugNacimiento,NomDepartamento
ORDER BY NomDepartamento
go

SELECT LugNacimiento,* from vAlumnos
where LugNacimiento = 'otro'
GO


--consulta por genero y valores en porcentajes
IF OBJECT_ID('usp_Alumno_ConsultaGenero') is not null
    DROP PROCEDURE usp_Alumno_ConsultaGenero
go
CREATE PROCEDURE usp_Alumno_ConsultaGenero
AS
BEGIN
    BEGIN TRANSACTION TransEjercicio
    BEGIN TRY
        SELECT CodEscuela,Escuela, COUNT(*) as TotalALumnos,
        SUM(CASE WHEN Sexo   = 'F' THEN 1 ELSE 0 END) AS TotalMujeres,
        cast(CAST((SUM(CASE WHEN Sexo   = 'F' THEN 1 ELSE 0 END)*100.0)/COUNT(*) as numeric(36,2))as varchar)+ '%' as PorcentajeMujeres,
        SUM(CASE WHEN Sexo = 'M' THEN 1 ELSE 0 END) AS TotalHombres,
        cast(CAST((SUM(CASE WHEN Sexo   = 'M' THEN 1 ELSE 0 END)*100.0)/COUNT(*) as numeric(36,2))as varchar)+ '%' as PorcentajeVarones
        from vAlumnos GROUP by CodEscuela,Escuela
    COMMIT TRANSACTION TransEjercicio
        SELECT CodError = 0, Mensaje = 'Transacción ejecutada correctamente'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION TransEjercicio
        SELECT CodError = 1, Mensaje = 'Error, la transacción no se ejecutó'
    END CATCH
END
GO

EXECUTE usp_Alumno_ConsultaGenero
go

--cantidad de alumnos por nacionalidad
select Nacionalidad, COUNT(*) as Cantidad from TAlumno
GROUP by Nacionalidad
ORDER by Nacionalidad
go  

--porcentaje de alumnos por escuela profesional
SELECT CodEscuela, Escuela, COUNT(*) as CantidadALumnos,
CAST(CAST(ROUND((COUNT(*)*100.0/(select COUNT(*) from vAlumnos)),2) as numeric(36,2)) AS varchar)
+ '%' AS Porcentaje from vAlumnos
GROUP by CodEscuela,Escuela
ORDER by COUNT(*) DESC
go

--Porcentaje de alumnos por genero 
select Sexo, COUNT(*) as Cantidad,
CAST(cast(ROUND((COUNT(*)*100.0/(select COUNT(*) from vAlumnos)),2)as numeric(36,2)) as varchar)
+ '%' as Porcentaje from vAlumnos GROUP by sexo
GO

--Cantidad de alumnos por regiones del Perú, los extranjeros estan agrupados por OTROS
SELECT NomDepartamento=(
    case when NomDepartamento=NomDepartamento
    then NomDepartamento
    else 'otros'
    end
), COUNT(*) as Cantidad from vAlumnos
GROUP by NomDepartamento
ORDER by NomDepartamento
go

--Alumnos organizados por erdades
SELECT SUM(CASE WHEN Edad < 18 THEN 1 ELSE 0 END) AS Menores_de_Edad,
        SUM(CASE WHEN Edad BETWEEN 18 AND 30 THEN 1 ELSE 0 END) AS [Entre 18 y 30 años],
        SUM(CASE WHEN Edad BETWEEN 31 AND 100 THEN 1 ELSE 0 END) AS [De 31 años a más]
FROM vAlumnos
GO


-----Tablero de datos que muestra el numero de varones y mujeres por cada escuela profesional
---y el promedio de mujeres y varones
IF OBJECT_ID('usp_TableroEdades') is not null
    DROP PROCEDURE usp_TableroEdades
go
create procedure usp_TableroEdades
as
Begin
    BEGIN TRANSACTION TransRango
    BEGIN TRY
    Declare @Escuela varchar(4)
    Declare @NroVarones int
    Declare @NroMujeres int
    Declare @i int
    Declare @nroRegistros int
    Declare @TotalF int
    Declare @TotalM int
    Declare @PromedioF int
    Declare @PromedioM int

    declare @table table
    (
    EscuelaAux varchar(2)
    )
    insert into @table 
    select distinct CodEscuela from vAlumnos
    
    set @NroRegistros = (select count(*) from @table)
    
    declare @Tablero table(
        Escuela varchar(2),
        NroMujeres int,
        NroVarones int )
    set @i=1
    set @TotalF=0
    set @TotalM=0
    while (@i<=@nroRegistros)
    Begin
        set @Escuela = (select max(EscuelaAux) from @table)
        set @NroMujeres=(select count(*) from vAlumnos where Sexo='F' 
                    and Edad between 18 and 20 and CodEscuela=@Escuela)
        set @NroVarones=(select count(*) from vAlumnos where Sexo='M' 
                    and Edad between 18 and 20 and CodEscuela=@Escuela)
        insert into @Tablero 
        select @Escuela,Isnull(@NroMujeres,0), Isnull(@NroVarones,0)
        delete from @table where EscuelaAux=@Escuela
        set @TotalF=@TotalF+@NroMujeres
        set @TotalM= @TotalM+@NroVarones
        set @i=@i+1
    end--fin de while
    --calculamos el promedio de mujeres y varones entre 18 y 23 años
    set @PromedioF= @TotalF/(@i-1)
    set @PromedioM=@TotalM/(@i-1)
    select * from  @Tablero
    union all
    select 'Promedio', @PromedioF,@PromedioM
    COMMIT TRANSACTION TransRango
        SELECT CodError = 0, Mensaje = 'Transacción ejecutada correctamente'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION TransRango
        SELECT CodError = 1, Mensaje = 'Error, la transacción no se ejecutó'
    END CATCH
End--- final
GO

EXECUTE usp_TableroEdades
go

--consulta inner de carga academica, matricula, alumno y docente
SELECT NroMatricula,M.CodAlumno,A.Nombres+' '+a.ApePaterno+' '+a.ApeMaterno as Alumno,M.CodCarga,C.CodDocente,C.CodCurso, m.SemAcademico,Nota 
from TCarAcademica C INNER JOIN TMatricula M INNER JOIN TAlumno A ON (A.CodAlumno=M.CodAlumno)
on (C.CodCarga=M.CodCarga) INNER JOIN TDocente D ON (c.CodDocente=D.CodDocente)
INNER join TCurso CU on (C.CodCurso=cu.CodCurso) ORDER BY M.NroMatricula
go

--tablero de matriculas con edades escuelas profesionales, cursos
IF OBJECT_ID('usp_Alumno_TableroMatriculas') is not null
    DROP PROCEDURE usp_Alumno_TableroMatriculas
GO
create PROCEDURE usp_Alumno_TableroMatriculas
as
BEGIN
    BEGIN TRANSACTION Trans
    BEGIN TRY
    BEGIN
    SELECT M.NroMatricula,M.CodAlumno,A.Alumno as Alumno,
    A.Edad,E.NomFacultad as Escuela,
    C.NomCurso as Curso, C.NroCreditos, C.Ciclo as CicloCurso, M.SemAcademico, M.Nota 
    from TMatricula M INNER JOIN vAlumnos A
    ON (M.CodAlumno = A.CodAlumno)
    inner JOIN TEscuela E on (A.CodEscuela = E.CodEscuela)
    INNER join TCurso C on (A.CodEscuela = C.CodEscuela)
    end
    COMMIT TRANSACTION Trans
        SELECT CodError = 0, Mensaje = 'Transacción ejecutada correctamente'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION Trans
        SELECT CodError = 1, Mensaje = 'Error, la transacción no se ejecutó'
    END CATCH
end
go

EXECUTE usp_Alumno_TableroMatriculas
go


--lista de alumnos que pertenecen al quinto superior
IF OBJECT_ID('usp_Alumno_QuintoSuperior') is not null
    DROP PROCEDURE usp_Alumno_QuintoSuperior
GO
create PROCEDURE usp_Alumno_QuintoSuperior
as
BEGIN
    BEGIN TRANSACTION Trans
    BEGIN TRY
    BEGIN
        select Alumno,Escuela,NomFacultad,M.Nota as Promedio  from vAlumnos A INNER join TMatricula M 
        ON(M.CodAlumno=A.CodAlumno) WHERE SemAcademico='2020-II' AND M.Nota  between 15 and 20
        order by M.Nota DESC
    end
    COMMIT TRANSACTION Trans
        SELECT CodError = 0, Mensaje = 'Transacción ejecutada correctamente'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION Trans
        SELECT CodError = 1, Mensaje = 'Error, la transacción no se ejecutó'
    END CATCH
end
go

EXECUTE usp_Alumno_QuintoSuperior
go

--consulta para exponer
select top 503 Alumno,Escuela,NomFacultad,M.Nota as Promedio  from vAlumnos A INNER join TMatricula M 
ON(M.CodAlumno=A.CodAlumno) WHERE SemAcademico='2020-II' AND M.Nota  between 14 and 20
order by M.Nota DESC
