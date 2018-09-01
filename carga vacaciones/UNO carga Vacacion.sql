
create procedure [pl].[CargaVacacion]
(

@Pkperiodo int  , --- =  (select top 1 periodo from #TEMPORAL)
@Pkderecho numeric(9,2),  -- =  (select top 1 derecho  from #TEMPORAL)
@Pkpagado numeric(9,2), --  =  (select top 1 pagado   from #TEMPORAL)
@empleadoId int, 
@proyectoId  int, 
@tipoplanillaId int,
@diaingreso varchar(2) ,
@mesingreso varchar(2) 

)
as


--select substring(rtrim(@Pkpagado), len(rtrim(@Pkpagado))-1, 2)
declare @complemento varchar(3)='.'+substring(rtrim(@Pkpagado), len(rtrim(@Pkpagado))-1, 2)
declare @PkmedioDia int = substring(rtrim(@Pkpagado), len(rtrim(@Pkpagado))-1, 2)
declare @PkDia int = REPLACE(RTRIM(@Pkpagado),@complemento  ,'')



IF (@PkMedioDia  =50)
BEGIN
SELECT 'MEDIO DIA'
END 
---- SELECT MUESTRA
--select @Pkperiodo  as perio , @Pkderecho as Derecho , @Pkpagado  as pagado


declare @nuevo bit =1

if (@Pkderecho = @Pkpagado)
begin
set @nuevo =0
end



 insert into dbo.Vacacion_Temporal(empleado_id , proyecto_id , tipo_planilla_id , Periodo , Derecho ,Pagado , Nuevo )
                             values(@empleadoId, @proyectoId , @tipoplanillaId , @Pkperiodo , @Pkderecho,@Pkpagado , @nuevo)
 
insert into pl.Empleado_Vacacion_Resumen(empleado_id ,proyecto_id ,tipo_planilla_id , Periodo , Derecho , Pagado , Nuevo, created_at , created_by)
values (@empleadoId , @proyectoId , @tipoplanillaId , @Pkperiodo , @Pkderecho , @Pkpagado , @nuevo, GETDATE(), 'Admin')



declare @fechaIn date 
declare @fechaFin date
if LEN(@mesingreso) =1
begin
set @mesingreso= '0'+@mesingreso
end
if LEN(@diaingreso) =1
begin
set @diaingreso = '0'+@diaingreso
end
set @fechaIn  = rtrim(@Pkperiodo+1) +@mesingreso +@diaingreso

set @fechaFin = DATEADD(day, @pkdia,@fechaIn)

--- Aceptado
insert into pl.Empleado_Vacacion(rh_empleado_id ,proyecto_id , tipo_planilla_id , fecha_inicio , dias,fecha_fin , monto ,
descripcion , pagada , gozada , created_at ,updated_at ,created_by ,updated_by ,estado , diaspaga, metodo_vacaciones,
fecha_inicio_planilla , fecha_fin_planilla , periodo)
				         values (@empleadoId , @proyectoId , @tipoplanillaId , @fechaIn, @PkDia  , @fechaFin  ,0.00,
'Migracion',1,1,GETDATE(), GETDATE(), 'Admin', 'Admin','Aceptado', @PkDia , 'Migracion',
@fechaIn , @fechaFin , @Pkperiodo )  


declare @EMPLEADOVACACIONID int
set @EMPLEADOVACACIONID = (select MAX(ID) FROM PL.Empleado_Vacacion)




declare @can int =0
while (@can < @pkDia )
begin
set @fechaIn  = rtrim(@Pkperiodo+1) +@mesingreso +@diaingreso
set @fechaIn = DATEADD(day,@can,@fechaIn)
--select @fechaIn
insert into pl.detalleVacacion(tipo_planilla_id , proyecto_id , empleado_vacacion_id , fecha, medio_dia , empleado_id)
                    values (@tipoplanillaId , @proyectoId , @EMPLEADOVACACIONID , @fechaIn, 0, @empleadoId )
                    
insert into pl.Empleado_Vacacion_Gozada(empleado_vacacion_id , dia, activo , periodo ,horas)
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,8)                     

insert into pl.Empleado_Vacacion_Gozada_Periodo(empleado_vacacion_id , dia, activo , periodo ,horas,monto )
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,8,0)                     

insert into pl.Empleado_Vacacion_Pagada(empleado_vacacion_id , dia, activo , periodo ,horas,monto_dia )
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,8,0)                     

insert into pl.Empleado_Vacacion_Pagada_Periodo(empleado_vacacion_id , dia, activo , periodo ,horas)
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,8)  
                    
set @can = @can+1
--select @can
end


IF (@PkMedioDia  =50)
BEGIN
set @fechaIn = DATEADD(day,@can,@fechaIn)
insert into pl.detalleVacacion(tipo_planilla_id , proyecto_id , empleado_vacacion_id , fecha, medio_dia , empleado_id)
                    values (@tipoplanillaId , @proyectoId , @EMPLEADOVACACIONID , @fechaIn, 1, @empleadoId )
                    
  
insert into pl.Empleado_Vacacion_Gozada(empleado_vacacion_id , dia, activo , periodo ,horas)
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,4)                     

insert into pl.Empleado_Vacacion_Gozada_Periodo(empleado_vacacion_id , dia, activo , periodo ,horas,monto )
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,4,0)                     

insert into pl.Empleado_Vacacion_Pagada(empleado_vacacion_id , dia, activo , periodo ,horas,monto_dia )
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,4,0)                     

insert into pl.Empleado_Vacacion_Pagada_Periodo(empleado_vacacion_id , dia, activo , periodo ,horas)
                 values(@EMPLEADOVACACIONID, @fechaIn , 1, @Pkperiodo,4)                      
                    
END 


GO

