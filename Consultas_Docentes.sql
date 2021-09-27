/*
Autor: Luis Mikhail Palomino Paucar
Fecha: 01/09/21
Vistas y procedimientos almacenados para docentes
TODO: implementar vistas, procedimientos almacenados etc
*/
USE master
go

use DBMATRICULA_DS
go

--tablero docente
IF OBJECT_ID('vDocente') is not NULL
    drop VIEW vDocente
GO

Create view vDocente
as
    Select CodDocente, Nombres as Docente, IndSexo as Sexo,Year(FecNacimiento) as YearNacimiento,
	(Year(GetDate())-Year(FecNacimiento)) as Edad, Especialidad,
	Nacionalidad,CodDepAcademico,NomDepAcademico from TDocente
GO

SELECT * from vDocente
go
--1. Por sexo
Select Sexo, count(*) as Cantidad
from vDocente
group by Sexo
---2 Por Departamentos Academicos nro de mujeres y varones
IF OBJECT_ID('usp_TableroDocentes') is not NULL
    DROP PROCEDURE usp_TableroDocentes
GO

create procedure usp_TableroDocentes
as
begin
    BEGIN TRANSACTION Trans
    BEGIN TRY
    Declare @DepAcademico varchar(5)
    Declare @NomDepAcademico varchar(100)
    Declare @NroVarones int
    Declare @NroMujeres int
    Declare @i int
    Declare @nroRegistros int
    declare @table table
    (
    DepAcademico varchar(5)
    )
    insert into @table 
    select distinct CodDepAcademico from vDocente
    set @NroRegistros = (select count(*) from @table)
    declare @Tablero table
        (
            Nro int,
            DepartamentoAcademico varchar(100),
            NroMujeres int,
            NroVarones int
                
        )
    set @i=1
    while (@i<=@nroRegistros)
    Begin
        set @DepAcademico = (select max(DepAcademico) from @table)
        set @NomDepAcademico=(select distinct nomDepAcademico from vDocente where CodDepAcademico=@DepAcademico)
        set @NroMujeres=(select count(*) from vDocente where Sexo='F' 
                    and CodDepAcademico=@DepAcademico)
        set @NroVarones=(select count(*) from vDocente where Sexo='M' 
                and CodDepAcademico=@DepAcademico)
    --- insertamos datos del primer rango
        insert into @Tablero 
        select @i,@NomDepAcademico,Isnull(@NroMujeres,0), Isnull(@NroVarones,0)
        ---calculamos los datos del segundo rango
    set @NroMujeres=(select count(*) from vDocente where Sexo='F' 
                    and Edad>40 and CodDepAcademico=@DepAcademico)
        set @NroVarones=(select count(*) from vDocente where Sexo='M' 
                    and Edad>40 and CodDepAcademico=@DepAcademico)
        delete from @table where DepAcademico=@DepAcademico
        set @i=@i+1
    end--fin de while
    --calculamos el promedio de mujeres y varones entre 18 y 23 a�os
        select * from @Tablero
    COMMIT TRANSACTION Trans
        SELECT CodError = 0, Mensaje = 'Transacción ejecutada correctamente'
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION Trans
        SELECT CodError = 1, Mensaje = 'Error, la transacción no se ejecutó'
    END CATCH
End--- final
go 

EXECUTE usp_TableroDocentes
go