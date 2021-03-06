
ALTER PROCEDURE  [pl].[CalculoPlanilla]
(
@planillacabecera int,
@usuario varchar(32)
)
as
BEGIN
--SET @planillacabecera  = 22
--SET @usuario  =  'admin'

DECLARE @CONTADOR INT
SET @CONTADOR =1
DECLARE @IDREG INT
select CAST(id as varchar(12)) as planillaid , identity(int,1,1) as id
into #temple  from pl.Planilla_Resumen where  planilla_cabecera_id = @planillacabecera  

while @CONTADOR  <= (select MAX(id) from #temple)
begin
set @IDREG = (SELECT  planillaid FROM #temple where id = @CONTADOR)
set @CONTADOR = @CONTADOR  +1
delete from pl.Planilla_Detalle  where planilla_resumen_id  = @IDREG 
delete from pl.Planilla_Resumen_Cuentas  where planilla_resumen_id  = @IDREG
end
delete from pl.Planilla_Resumen  where planilla_cabecera_id  = @planillacabecera 
DROP TABLE #temple 

select pl.tipo_planilla_id,  pl.anticipo as 'Es_Anticipo', t.porcentaje_anticipo, CONVERT(varchar(10), pl.fecha_inicio ,112) as inicio,
CONVERT(varchar(10), pl.fecha_fin ,112)  as fin,fe.diasbase, fe.horasbase, 
ss.empleado_porcentaje,  ss.patrono_porcentaje,  ss.intecap_porcentaje, ss.irtra_porcentaje,  
provision_aguinaldo, provision_bono14, provision_indemnizacion, provision_vacaciones, pl.proyecto_id,
case when calendario_comercial = 0 and fe.dias_calendario =30 then   DATEDIFF(day, fecha_inicio, fecha_fin)+1
else  fe.dias_calendario end 
dias_calendario, dias_septimo, usa_anticipo_seguro_social,usa_anticipo_bonificacion, calendario_comercial,
isnull(fe.septimo,0) as Usa_Septimo , day(pl.fecha_inicio) as dia, t.salario_dia
into  #tablaVariables 
 from rh.Tipo_Planilla  t 
inner join pl.Planilla_Cabecera  pl on t.id = pl.tipo_planilla_id
inner join cat.FrecuenciaPago  fe on fe.id = t.frecuencia_pago_id  
inner join cat.Tipo_ss  ss on t.tipo_ss_id = ss.id  where pl.id = @planillacabecera  


--#region INICIALES PARA CALCULO
declare @salario_dia int                        SET @salario_dia = (select salario_dia from #tablaVariables )
declare @dia int                                     SET @dia= (select dia from #tablaVariables )
declare @tipo_planilla_id int                        SET @tipo_planilla_id= (select tipo_planilla_id from #tablaVariables )
declare @usa_anticipo bit                       SET @usa_anticipo = (select usa_anticipo_quincenal   from rh.Tipo_Planilla where id = @tipo_planilla_id)
declare @Es_Anticipo bit                                   SET @Es_Anticipo = (select Es_Anticipo from #tablaVariables )
declare @porcentaje_anticipo numeric(9,2)      SET @porcentaje_anticipo = (select porcentaje_anticipo from #tablaVariables )
declare @fechaini varchar(10)                        SET @fechaini = (select inicio from #tablaVariables )
declare @fechafin varchar(10)                        SET @fechafin = (select fin from #tablaVariables )
declare @diasbase int                                      SET @diasbase = (select diasbase from #tablaVariables )
declare @horasdiarias int                                  SET @horasdiarias = (select horasbase from #tablaVariables )
--declare @septimo int                                     SET @septimo = (select septimo from #tablaVariables )
declare @empleado_porcentaje numeric(9,2)      SET @empleado_porcentaje = (select empleado_porcentaje from #tablaVariables )
declare @patrono_porcentaje numeric(9,2)       SET @patrono_porcentaje = (select patrono_porcentaje from #tablaVariables )
declare @intecap_porcentaje  numeric(9,2)      SET @intecap_porcentaje = (select intecap_porcentaje from #tablaVariables )
declare @irtra_porcentaje numeric(9,2)               SET @irtra_porcentaje = (select irtra_porcentaje from #tablaVariables )
declare @provision_aguinaldo numeric(9,2)      SET @provision_aguinaldo = (select provision_aguinaldo from #tablaVariables )
declare @provision_bono14 numeric(9,2)               SET @provision_bono14 = (select provision_bono14 from #tablaVariables )
declare @provision_indemizacion numeric(9,2)   SET @provision_indemizacion = (select provision_indemnizacion from #tablaVariables )
declare @provision_vacaciones numeric(9,2)           SET @provision_vacaciones = (select provision_vacaciones from #tablaVariables )
declare @proyecto_id  int                       SET @proyecto_id = (select proyecto_id from #tablaVariables )
declare @dias_calendario int                    SET @dias_calendario  = (select dias_calendario from #tablaVariables ) 
declare @dias_septimo int                       SET @dias_septimo  = (select dias_septimo from #tablaVariables )  
declare @usa_anticipo_seguro_social bit         SET @usa_anticipo_seguro_social=(select  usa_anticipo_seguro_social from #tablaVariables )  
declare @usa_anticipo_bonificacion bit          SET @usa_anticipo_bonificacion=(select  usa_anticipo_bonificacion from #tablaVariables ) 
declare @calendario_comercial bit               SET @calendario_comercial=(select  calendario_comercial from #tablaVariables ) 
declare @Usa_Septimo  bit                       SET @Usa_Septimo=(select  Usa_Septimo from #tablaVariables )   

set @Usa_Septimo = ISNULL(@Usa_Septimo,0)
set @salario_dia = ISNULL(@salario_dia,0)
drop table #tablaVariables
declare @diasajuste int
set @diasajuste  = 0

if (@diasbase =30 or @diasbase =31) and @dia >1
begin
SET @diasajuste =@diasbase- @dia
set @diasajuste = @diasbase -@diasajuste  
end

DECLARE @empleado_id int
DECLARE @CONTE int
SET @CONTE = 1

print 'Porcentaje anticipo'
print @porcentaje_anticipo
 
--select  fecha_baja, empleado_id, IDENTITY(int, 1, 1) as conte INTO #TEMPEMPLEADOS from rh.Empleado_Proyecto 
-- where
-- ( activo =1 and tipo_planilla_id = @tipo_planilla_id  and proyecto_id = @proyecto_id 
-- and fecha_alta <=@fechafin  and empleado_id in (select id from rh.Empleado )
-- )
-- --or (activo =0 and tipo_planilla_id =@tipo_planilla_id  and proyecto_id =@proyecto_id 
-- --and  fecha_baja > = @fechaini      and fecha_baja < =@fechafin   )
 
create table #TEMPEMPLEADOS (empleado_id int, conte int )

select   empleado_id, IDENTITY(int, 1, 1) as conte INTO #TEMPEMPLEADOS2 from rh.Empleado_Proyecto 
 where
(  ( activo =1 and tipo_planilla_id = @tipo_planilla_id  and proyecto_id = @proyecto_id 
 and fecha_alta <=@fechafin  and empleado_id in (select id from rh.Empleado )
 and empleado_id in (select id from rh.Empleado ))
  or (activo =0 and tipo_planilla_id =@tipo_planilla_id  and proyecto_id =@proyecto_id 
 and  fecha_baja > = @fechaini      and fecha_baja < =@fechafin  and DAY(fecha_baja) > 15 ) 
 
 )

select   empleado_id, IDENTITY(int, 1, 1) as conte INTO #TEMPEMPLEADOS1 from rh.Empleado_Proyecto 
 where
(  ( activo =1 and tipo_planilla_id = @tipo_planilla_id  and proyecto_id = @proyecto_id 
 and fecha_alta <=@fechafin  and empleado_id in (select id from rh.Empleado )
 and empleado_id in (select id from rh.Empleado ))
  or (activo =0 and tipo_planilla_id =@tipo_planilla_id  and proyecto_id =@proyecto_id 
 and  fecha_baja > = @fechaini      and fecha_baja < =@fechafin and DAY(fecha_baja) <= 15 ) )



if (@Es_Anticipo = 1)
begin
insert into #TEMPEMPLEADOS (empleado_id, conte)
select empleado_id , conte  from #TEMPEMPLEADOS1
end
else
begin
insert into #TEMPEMPLEADOS (empleado_id, conte)
select empleado_id , conte  from #TEMPEMPLEADOS2
end

drop table #TEMPEMPLEADOS2
drop table #TEMPEMPLEADOS1

--empleado_id in (select RTRIM(id) from dbo.Marzo15)
 
--select * from #TEMPEMPLEADOS

 
while (@CONTE <=(select MAX(conte) from #TEMPEMPLEADOS))
begin
      set @empleado_id  = (select empleado_id from #TEMPEMPLEADOS where conte = @CONTE)  
 --      if (@empleado_id=592)
 --begin
 --select 'aaui'
 --end

       print @empleado_id
      set @CONTE  = @CONTE  +1
     -- select @empleado_id as empleado

print '*_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-'             
   
   declare @codigoPlan varchar(10) = (select abreviatura from rh.Tipo_Planilla where id = @tipo_planilla_id)
   set @codigoPlan = ISNULL(@codigoPlan,'')
   set @codigoPlan = RTRIM(@codigoPlan)
   if (@codigoPlan='HORA')
   BEGIN   
      EXEC  pl.CalculoPlanillaEmpleadoHora 
            @planillacabecera,  @empleado_id,
            @usuario, @tipo_planilla_id, @Es_Anticipo,                             
            @porcentaje_anticipo, @fechaini, @fechafin,                            
            @diasbase,  @horasdiarias,    @empleado_porcentaje,        
            @patrono_porcentaje,@intecap_porcentaje,@irtra_porcentaje,       
            @provision_aguinaldo, @provision_bono14,@provision_indemizacion, 
            @provision_vacaciones, @proyecto_id,@dias_calendario,
            @usa_anticipo_seguro_social,@usa_anticipo_bonificacion, @calendario_comercial,
            @Usa_Septimo , @diasajuste , @salario_dia    
        END
        ELSE
        BEGIN
              EXEC  pl.CalculoPlanillaEmpleado 
            @planillacabecera,  @empleado_id,
            @usuario, @tipo_planilla_id, @Es_Anticipo,                             
            @porcentaje_anticipo, @fechaini, @fechafin,                            
            @diasbase,  @horasdiarias,    @empleado_porcentaje,        
            @patrono_porcentaje,@intecap_porcentaje,@irtra_porcentaje,       
            @provision_aguinaldo, @provision_bono14,@provision_indemizacion, 
            @provision_vacaciones, @proyecto_id,@dias_calendario,
            @usa_anticipo_seguro_social,@usa_anticipo_bonificacion, @calendario_comercial,
            @Usa_Septimo , @diasajuste , @salario_dia  
        
        END    
            
            
            
            
print  'pl.CalculoPlanillaEmpleado' +rtrim(@planillacabecera) +','+ rtrim(@empleado_id)+','
print rtrim(@usuario)+','+ rtrim(@tipo_planilla_id)+','+ rtrim(@Es_Anticipo)+','                    
print rtrim(@porcentaje_anticipo)+','+ rtrim(@fechaini)+','+  rtrim(@fechafin)+','                        
print rtrim(@diasbase)+','+   rtrim(@horasdiarias)+','+      rtrim(@empleado_porcentaje)+','          
print      rtrim(@patrono_porcentaje)+','+rtrim(@intecap_porcentaje)+','+rtrim(@irtra_porcentaje)+','
print   rtrim(@provision_aguinaldo)+','+rtrim(@provision_bono14)+','+rtrim(@provision_indemizacion)+','
print   rtrim(@provision_vacaciones)+','+ rtrim(@proyecto_id)+','+rtrim(@dias_calendario)+','
print rtrim(@usa_anticipo_seguro_social)+','+rtrim(@usa_anticipo_bonificacion)+',' +rtrim(@calendario_comercial)+','
print ','+rtrim(@Usa_Septimo)
print  ','+ rtrim(@diasajuste)
print ','+rtrim(@salario_dia)    
            
            
print '*_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-'                   
                       
end

select @planillacabecera
drop table #TEMPEMPLEADOS

END
