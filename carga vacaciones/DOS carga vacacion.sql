
create  procedure [pl].[CargaEmpleadoVacacion]
(

 @CODIGO varchar(50), -- ='INPRO-935'
 @DIAPENDIENTE numeric(9,2), -- = 11
 @ULTIMOPERIODO int -- =2017

)
as
---- PARAMETRO INICIALES
declare @diaDerecho int =15
if (@ULTIMOPERIODO=2018)
begin
declare @fechaalta date= (select fecha_alta from rh.Empleado_Proyecto  where codigo ='INPRO-2898')
declare @diaint numeric(9,2)
set @diaint=( select datediff(day, @fechaalta,getdate()) )
declare @dia numeric(9,2)
set @dia=(select (@diaint*15)/365)
if (@dia <15)
begin
set @diaDerecho=@dia
end

end

declare @fechaHoy date = getdate()


declare @fechaingreso date =(select  top 1 fecha_alta from rh.Empleado_Proyecto where codigo = @codigo order by id desc)
declare @empleadoId int = (select  top 1 empleado_id from rh.Empleado_Proyecto where codigo = @codigo order by id desc)
declare @proyectoId int = (select  top 1 proyecto_id  from rh.Empleado_Proyecto where codigo = @codigo order by id desc)
declare @tipoplanillaId int = (select  top 1 tipo_planilla_id  from rh.Empleado_Proyecto where codigo = @codigo order by id desc)
declare @diaingreso varchar(2) =(select  top 1 day(fecha_alta) from rh.Empleado_Proyecto where codigo = @codigo order by id desc)
declare @mesingreso varchar(2) =(select  top 1 month(fecha_alta) from rh.Empleado_Proyecto where codigo = @codigo order by id desc)



 
delete from dbo.Vacacion_Temporal where empleado_id = @empleadoId

delete from pl.Empleado_Vacacion_Gozada  where empleado_vacacion_id  in (select id from pl.Empleado_Vacacion where rh_empleado_id = @empleadoId)
delete from pl.Empleado_Vacacion_Pagada   where empleado_vacacion_id  in (select id from pl.Empleado_Vacacion where rh_empleado_id = @empleadoId)
delete from pl.Empleado_Vacacion_Gozada_Periodo   where empleado_vacacion_id  in (select id from pl.Empleado_Vacacion where rh_empleado_id = @empleadoId)
delete from pl.Empleado_Vacacion_Pagada_Periodo   where empleado_vacacion_id  in (select id from pl.Empleado_Vacacion where rh_empleado_id = @empleadoId)
delete from pl.detalleVacacion    where empleado_vacacion_id  in (select id from pl.Empleado_Vacacion where rh_empleado_id = @empleadoId)
delete from pl.Empleado_Vacacion_Resumen  where empleado_id = @empleadoId
delete from pl.Empleado_Vacacion  where rh_empleado_id = @empleadoId
--delete from pl.Empleado_Vacacion_Resumen  where empleado_id = @empleadoId 


declare @periodoInicial int =year(@fechaingreso)
---COMENTADO
--set @periodoInicial=2017
declare @bandera int =0
---------------------------------------------------------------------------



---- PARA OBTENER DIAS PERIODOS---------------------------------------------
declare @diasTotal numeric(9,2) = DATEDIFF(day,@fechaingreso, @fechaHoy) 
declare @resta numeric(9,2) =  @diasTotal % 365
declare @periodosCompletos int= (@diasTotal-@resta )/365
declare @cola numeric(9,2) = (@resta * @diaDerecho )/ 365

----SELECT MUESTRA
select @periodoInicial as periodoInicial,@fechaingreso as fechaIngreso,  @fechaHoy as fecha,
@periodosCompletos as Periodos_completos, @cola as Pendiente,@ULTIMOPERIODO as Ultimoperiodo, @DIAPENDIENTE as diaPendiente
--------------------------------------------------------------------------



------CREAR UN TEMPORAL PARA GRABAR
create TABLE #TEMPORAL(id int IDENTITY(1,1) NOT NULL, codigo varchar(10), empleadoId int, periodo int, derecho numeric(9,2), pagado numeric(9,2))
declare @per int
declare @contador int =0
declare @pagado numeric(9,2)= 0


while (@contador <= (@periodosCompletos))
begin
   set @per  = @periodoInicial+ @contador
   set @pagado = @diaDerecho
   IF  @ULTIMOPERIODO = @per 
   BEGIN
       set @pagado = @diaDerecho - @DIAPENDIENTE
   END
   if @pagado <0
   begin
   set @pagado=0
   end
   if (@bandera=0)
   begin
        insert into #TEMPORAL (codigo, empleadoId, periodo , derecho ,pagado )
        values (@CODIGO , @empleadoId , @per , @diaDerecho , @pagado)
   end
  IF  @ULTIMOPERIODO = @per
  BEGIN
      set @bandera=1
  end
  set @contador = @contador+1
end


if (@cola >0)
begin
    set @per= @periodoInicial+ @contador
    set @pagado = 0
       IF  @ULTIMOPERIODO = @per 
   BEGIN
       set @pagado = @cola - @DIAPENDIENTE
   END
    if (@bandera=0)
    begin
         insert into #TEMPORAL (codigo, empleadoId, periodo , derecho ,pagado )
          values (@CODIGO , @empleadoId , @per , @cola  ,@pagado )
     end
end
---- BARREMOS TABLA

--select * from #TEMPORAL
declare @contab int=0
while (@contab  < (select MAX(Id) from #TEMPORAL))
begin
set  @contab = @contab+1
declare @Pkperiodo int  =  (select top 1 periodo from #TEMPORAL where id = @contab )
declare @Pkderecho numeric(9,2) =  (select top 1 derecho  from #TEMPORAL where id = @contab )
declare @Pkpagado numeric(9,2) =  (select top 1 pagado   from #TEMPORAL where id = @contab )
exec Pl.CargaVacacion @Pkperiodo,@Pkderecho ,@Pkpagado , @empleadoId, @proyectoId,@tipoplanillaId,@diaingreso,@mesingreso 
--select @Pkpagado , @Pkderecho , @Pkperiodo 
end





drop table #TEMPORAL
-- select * from #TEMPORAL
------------------VARIABLES PARA EJECUTAR  --- CREAR PROCEDURE
--declare @Pkperiodo int  =  (select top 1 periodo from #TEMPORAL)
--declare @Pkderecho numeric(9,2) =  (select top 1 derecho  from #TEMPORAL)
--declare @Pkpagado numeric(9,2) =  (select top 1 pagado   from #TEMPORAL)






select * from pl.Empleado_Vacacion_Resumen where empleado_id = @empleadoId











GO

