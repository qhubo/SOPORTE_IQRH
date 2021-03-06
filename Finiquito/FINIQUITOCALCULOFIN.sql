

ALTER procedure [pl].[CalculoRetiroMONTO]
(
@idretiro int, -- =188
@bonIndemizacion int, --
@horasIndemizacion int, --
@ingresosIndemizacion int, --
@monto numeric (9,2)  out
)
as

--set @horasIndemizacion = 1
--set @ingresosIndemizacion =1
--set @bonIndemizacion =0





CREATE TABLE  #HISTORIO  (empleado_id int,fecha_inicio date, fecha_fin date, dias_base numeric(9,2),dias_laborados numeric(9,2), sueldo_base numeric(9,2),
bonificacion_base numeric(9,2), sueldo_base_recibido numeric(9,2),bonificacion_base_recibido numeric(9,2), ingresos_afectos_prestaciones numeric(9,2),total_extras numeric(9,2))


-- DETALLE VARIABLES
DECLARE @DIASMES  int = 30
DECLARE @DIASPERIODO int = 365 
---*** DATOS DEL CALCULO DE RETIRO
select  proyecto_id, tipo_planilla_id,   calcular_base, metodo, porcentaje_indemizacion,
paga_indemizacion, bonificacion_indemizacion, horas_indemizacion,
ingresos_indemizacion, pl.empleado_id,fecha_alta, fecha_baja   into   #detalleEmpleado from  pl.Empleado_Retiro pl
inner join rh.Empleado_Proyecto  pr on pl.empleado_proyecto_id  = pr.id where pl.id = @IDRETIRO

--SELECT * FROM #detalleEmpleado
declare @IDEMPLEADO INT
declare @proyecto_id  int 
declare @tipo_planilla_id int
-- # POBLAR DATOS
declare @calcular_base varchar(100) -- ultimo sueldo  - promedio 
declare @metodo varchar(100) -- devengado percibido
declare @porcentaje_inde int
declare @paga_indemiza int

declare @12VABONO numeric(9,2) 
declare @12VAGUIN  numeric(9,2)
declare @fechaalta date
declare @fechabaja date
---*** VARIABLES AFECTAN CALCULO VACACIONES
SET @IDEMPLEADO = (select  empleado_id from #detalleEmpleado )
SET @proyecto_id =(select proyecto_id from #detalleEmpleado )
SET @tipo_planilla_id =(select tipo_planilla_id from #detalleEmpleado )
SET @calcular_base = (select calcular_base from #detalleEmpleado )
SET @metodo = (select rtrim(metodo) from #detalleEmpleado )
SET @porcentaje_inde = (select porcentaje_indemizacion from #detalleEmpleado )
SET @paga_indemiza = (select paga_indemizacion from #detalleEmpleado )


set @fechaalta  = (select   fecha_alta from #detalleEmpleado )
set @fechabaja  = (select fecha_baja from #detalleEmpleado)
--- ***     SETEO DE VARIABLES




drop table  #detalleEmpleado 

declare @DIAS_TOTAL_LABORADOS numeric(9,2)
DECLARE @NO_MESES INT
DECLARE @MES_FINAL DATE
--ELIMINAMOS REGISTRO ANTERIOR

--****--- SALARIO BONIFICACION
declare @SALARIO numeric(9,2)
SET @SALARIO = (select top 1   isnull(salario,0)  from rh.Empleado_Proyecto  where empleado_id  = @IDEMPLEADO  and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id order by fecha_alta  desc)  -- and activo =1)     
declare @BONIFICACION numeric(9,2)
SET @BONIFICACION = (select top 1   isnull(bono_base,0)  from rh.Empleado_Proyecto  where empleado_id  = @IDEMPLEADO   and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id order by fecha_alta  desc)  -- and activo =1)     

set @DIAS_TOTAL_LABORADOS = (select  sum(dias_laborados)  from
pl.VW_PLANILLA 
--  pl.Planilla_Resumen r inner join  pl.Planilla_Cabecera c on c.id = r.planilla_cabecera_id  
where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id
and proyecto_id = @proyecto_id  and ISNULL(vacacion,0)=0 and bono=0 and aguinaldo =0  AND anticipo =0 )

set @NO_MESES =  (select  COUNT(*)  from 
pl.VW_PLANILLA 
-- pl.Planilla_Resumen r inner join  pl.Planilla_Cabecera c on c.id = r.planilla_cabecera_id  
where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id
and proyecto_id = @proyecto_id  and ISNULL(vacacion,0)=0 and bono=0 and aguinaldo =0  AND anticipo =0)

set @MES_FINAL =  (select  MAX(fecha_inicio)   from 
-- pl.Planilla_Resumen r inner join  pl.Planilla_Cabecera c on c.id = r.planilla_cabecera_id  
pl.VW_PLANILLA 
where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id
and proyecto_id = @proyecto_id  and ISNULL(vacacion,0)=0 and bono=0 and aguinaldo =0  AND anticipo =0)
print  ' CONTRATO ---------------------------------'
print  ' SALARIO '+rtrim(@SALARIO)+' BONIFICACION ' + RTRIM(@BONIFICACION) 
     + ' DIAS TOTAL LABORADOS ' + RTRIM(@DIAS_TOTAL_LABORADOS) + ' NUMERO PLANILLAS ' +RTRIM(@NO_MESES)
--select @SALARIO as Salario, @BONIFICACION as bonificacion, @DIAS_TOTAL_LABORADOS as dias
print  ' -------------------------------------------'
---** PARA LOS QUE NO TIENE 6 MESES 
if ((@calcular_base= 'Promedio Seis Meses' )  AND (@NO_MESES  >=6))    
BEGIN
PRINT ' OPCION DE HISTORICO *****PROMEDIO SEIS MESES' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )


select   empleado_id,  c.fecha_inicio , c.fecha_fin ,  sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados,  sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras
--  from pl.Planilla_Resumen  p inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
from pl.VW_PLANILLA  c
where empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
and c.activo = 0  and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0 and ISNULL(bono,0) = 0 
and dias_laborados > 0 
--and  fecha_inicio 
and fecha_inicio >= DATEADD (MONTH,-6, @MES_FINAL) 
group by empleado_id ,c.fecha_inicio , c.fecha_fin
order by c.fecha_inicio  desc 


END
if ((@calcular_base= 'Promedio Doce Meses' ) AND (@NO_MESES  >=12))    
BEGIN
PRINT ' OPCION DE HISTORICO  *****DOCE MESES' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )
select  empleado_id, fecha_inicio , fecha_fin ,  sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados,  sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras from 
--pl.Planilla_Resumen  p inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
pl.VW_PLANILLA 
where empleado_id  = @IDEMPLEADO  and proyecto_id  = @proyecto_id  
and tipo_planilla_id  = @tipo_planilla_id   and anticipo  = 0
and activo = 0  and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0 and ISNULL(bono,0) = 0 
and dias_laborados > 0 
and fecha_inicio >= DATEADD (MONTH,-12, @MES_FINAL) 
group by empleado_id ,fecha_inicio , fecha_fin
order by fecha_inicio  desc 
END
if   (SELECT COUNT(*) FROM #HISTORIO )   <= 6 AND (SELECT COUNT(*) FROM #HISTORIO )   >= 0 
BEGIN
PRINT ' OPCION DE HISTORICO  *****TODO SU HISTORICO' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )
select  empleado_id,  c.fecha_inicio , c.fecha_fin ,  
sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados, 
sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras from
-- pl.Planilla_Resumen  p  inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
pl.VW_PLANILLA  c
where empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
and c.activo = 0  and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0 and ISNULL(bono,0) = 0 
and dias_laborados > 0 
--and fecha_inicio >= DATEADD (MONTH,-6, @MES_FINAL) 
group by empleado_id ,c.fecha_inicio , c.fecha_fin
order by c.fecha_inicio  desc 
END




--declare @diava int
--set @diava = (
--select  c.dias_calendario  from rh.Tipo_Planilla  t  inner join cat.FrecuenciaPago c 
--on c.id = t.frecuencia_pago_id  where t.id = @tipo_planilla_id )

if   (SELECT COUNT(*) FROM #HISTORIO )   =0
BEGIN
PRINT ' OPCION DE HISTORICO  *****NO HAY HISTORICO' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )
select empleado_id , fecha_alta as fecha_inicio ,
fecha_alta as fecha_fin ,  30  as dias_base,30 as dias_laborados,
salario as sueldo_base, bono_base as bonificacion_base, salario  as sueldo_base_recibido,
bono_base as bonificacion_base_recibido, 0 as ingresos_afectos_prestaciones,
0 as total_extras    from rh.Empleado_Proyecto where empleado_id = @IDEMPLEADO
END
select    * INTO #DETALLE from #HISTORIO --where fecha_inicio <> '2018-08-01' 
ORDER BY fecha_inicio DESC

select * from #DETALLE 

DECLARE @DIASLABORADOS numeric(9,2)= (select SUM(dias_laborados) from #DETALLE)


DECLARE @DIARECIBIDO numeric(9,2) = (select   SUM(dias_laborados) from #DETALLE)
--if (@metodo ='Percibido (Pagado Real)') 
--begin
--set @DIARECIBIDO=180
--end

DECLARE @DIADEVENGADO numeric(9,2) = (select   SUM(dias_base) from #DETALLE)


DECLARE @DIASBASE numeric(9,2)= (select   SUM(dias_base) from #DETALLE)
DECLARE @SALARIOBASE numeric(9,2)  = (select   sum(sueldo_base)  from #DETALLE)
DECLARE @BONIFICACIONBASE  numeric(9,2)  = (select   sum(bonificacion_base)  from #DETALLE)
DECLARE @SALARIORECIBIDA  numeric(9,2)  = (select   sum(sueldo_base_recibido)  from #DETALLE)
DECLARE @BONIFICACIONRECIBIDA  numeric(9,2)  = (select sum(bonificacion_base_recibido)     from #DETALLE)
DECLARE @EXTRAS numeric(9,2)  = (select   sum(total_extras)  from #DETALLE)
DECLARE @INGRESOS numeric(9,2)  = (select   sum(ingresos_afectos_prestaciones)  from #DETALLE)
SET @INGRESOS = (SELECT  ISNULL(SUM( ingresos_afectos_prestaciones),0)  FROM 
--PL.Planilla_Resumen 
pl.VW_PLANILLA  WHERE empleado_id =@IDEMPLEADO)

DECLARE @MONTOPERCIBIDO numeric(9,2) 
DECLARE @MONTODEVENGADO numeric(9,2)
DECLARE @MONTOBONIFI numeric(9,2)
declare @montomensual numeric (9,2)
declare @montodiario numeric(9,2)
declare @montoDiarioUnico numeric(9,2)
declare @TOTALG numeric(9,2)
declare @diarioIN numeric(9,2)
DECLARE @DIATOTAL numeric(9,2)
set @MONTOPERCIBIDO =  @SALARIORECIBIDA   
set @MONTODEVENGADO  = @SALARIOBASE
if @DIASLABORADOS  =0
BEGIN
SET @DIASLABORADOS =1
END
DECLARE @diasderecho numeric(9,2)
set @diasderecho  = ( select pl.funDiasComerciales(@fechaalta, @fechabaja))  +1 
set @diasderecho  = ( select datediff(day,@fechaalta, @fechabaja))  +1 
print  'DIAS DERECHO --------------------------------------------'
print 'dias total derecho  ' + rtrim(@diasderecho)
print '----------------------------------------------'

if RTRIM(@metodo)  = 'Percibido (Pagado Real)'
BEGIN

PRINT  ' PROMEDIO  ' + RTRIM((@INGRESOS / @DIADEVENGADO )  * @DIASMES)
set @TOTALG  = @MONTOPERCIBIDO 

select @MONTOPERCIBIDO as Monto, @DIARECIBIDO  as diaslaorados, @DIADEVENGADO as diasdev
-- SET  @DIATOTAL = @DIARECIBIDO
set @DIATOTAL = @DIADEVENGADO
set @MONTOBONIFI  = @BONIFICACIONBASE 
END
ELSE
BEGIN
set @TOTALG  = @MONTODEVENGADO 
SET  @DIATOTAL = @DIADEVENGADO 
set @MONTOBONIFI  = @BONIFICACIONRECIBIDA 
END
PRINT  '-----------  DETALLE DE CALCULO ---------'

drop table #HISTORIO
DECLARE @PROMEDIOMENSUAL numeric(9,2)
set  @PROMEDIOMENSUAL= (@TOTALG /@DIATOTAL ) *@DIASMES
--- aplicac ingresos
if @ingresosIndemizacion =1
begin
PRINT  '-----------APLICA INGRESOS---------'
set  @PROMEDIOMENSUAL=  ((@INGRESOS /@DIATOTAL ) *@DIASMES) +@PROMEDIOMENSUAL
end

SET @12VABONO = @PROMEDIOMENSUAL/12
SET @12VAGUIN = @PROMEDIOMENSUAL/12

--- aplica bonifica
if @bonIndemizacion =1
begin
PRINT  '-----------APLICA BONIFICACION---------'
set  @PROMEDIOMENSUAL=  ((@MONTOBONIFI /@DIATOTAL ) *@DIASMES) +@PROMEDIOMENSUAL
end

select @PROMEDIOMENSUAL AS  PromedioMensualAntesExtras
-- aplica extras
if @horasIndemizacion =1
begin
--PRINT  '-----------APLICA EXTRAS---------'
set  @PROMEDIOMENSUAL=  ((@EXTRAS/@DIATOTAL)  *@DIASMES ) +@PROMEDIOMENSUAL

select @EXTRAS as SumaExtras, @DIATOTAL as DiaTotal , @EXTRAS/@DIATOTAL as promedioExtras,
@DiasMes as diaMEs, ((@EXTRAS/@DIATOTAL)  *@DIASMES )  as ValorExtra


end

select @PROMEDIOMENSUAL AS  PromedioMensualDespuesExtras

SET @montodiario = @PROMEDIOMENSUAL/@DIASMES


declare @valorindemizacion  numeric(9,2)
--SET @valorindemizacion= ((@PROMEDIOMENSUAL + @12VABONO+ @12VAGUIN) * @diasderecho)/@DIASPERIODO


set @monto = @montodiario

-- select @montodiario

DROP TABLE #DETALLE



GO
ALTER PROCEDURE  [pl].[CalculoRetiroVacaciones]
(
@IDRETIRO int,
@USUARIO varchar(50)
)
as
--set @IDRETIRO = 5 
BEGIN
DECLARE @DIASMES  int = 30
DECLARE @DIASPERIODO int = 365

delete from  pl.Empleado_Retiro_detalle  where Empleado_Retiro_Id  = @IDRETIRO
and Tipo ='Vacaciones'

--delete from  pl.Empleado_Retiro_detalle  where Empleado_Retiro_Id  = @IDRETIRO
--and Tipo ='Vacaciones'
--declare @IDRETIRO INT
--set @IDRETIRO  = 18
--declare  @USUARIO varchar(50)

select  proyecto_id, tipo_planilla_id,  calcular_base_vacaciones, metodo, porcentaje_indemizacion,
bonificacion_vacaciones , horas_vacaciones ,ingresos_vacaciones , pl.empleado_id, dias_vacaciones_paga ,
fecha_baja
into   #detalleEmpleado from  pl.Empleado_Retiro pl
inner join rh.Empleado_Proyecto  pr on pl.empleado_proyecto_id  = pr.id where pl.id = @IDRETIRO

declare @IDEMPLEADO INT
declare @proyecto_id  int 
declare @tipo_planilla_id int
--declare @bonVacaciones int
--declare @horasVacaciones int
declare @ingresosvacaciones int
declare @metodo varchar(100) -- devengado percibido
declare @dias_vacaciones_paga numeric(9,2)
declare @fechabaja date
declare @calcular_base_vacaciones varchar(100)

SET @metodo = (select metodo from #detalleEmpleado )
SET @IDEMPLEADO = (select  empleado_id from #detalleEmpleado )
SET @proyecto_id =(select proyecto_id from #detalleEmpleado )
SET @tipo_planilla_id =(select tipo_planilla_id from #detalleEmpleado )
--SET @bonVacaciones  = (select bonificacion_vacaciones from #detalleEmpleado )
--SET @horasVacaciones  = (select horas_vacaciones from #detalleEmpleado )
SET @ingresosvacaciones  =(select ingresos_vacaciones from #detalleEmpleado )
set @dias_vacaciones_paga = (select dias_vacaciones_paga from #detalleEmpleado)
set @fechabaja  = (select fecha_baja from #detalleEmpleado)
set @calcular_base_vacaciones = (select calcular_base_vacaciones from #detalleEmpleado)
drop table  #detalleEmpleado 

DECLARE @diasdercho int
set @diasdercho  = (select isnull(dias_vacaciones,0)  from rh.Empleado  where id = @IDEMPLEADO )
declare @SALARIO numeric(9,2)
EXEC pl.SalarioEmpleado @IDEMPLEADO,@proyecto_id ,@tipo_planilla_id ,@SALARIO OUT


DECLARE @fecha_inicio date
set @fecha_inicio  =(select top 1  fecha_inicio  
from pl.VW_PLANILLA  where empleado_id  = @IDEMPLEADO 
and proyecto_id  = @proyecto_id and tipo_planilla_id  = @tipo_planilla_id 
and anticipo  = 0 and activo = 0 
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 
order by fecha_inicio  desc )



DECLARE @DIASLABORADOS numeric(9,2) -- = (select   dias_laborados  from #todos)
DECLARE @DIASBASE numeric(9,2) -- = (select   dias_base  from #todos)
DECLARE @SALARIOBASE numeric(9,2) --   = (select   sueldo_base  from #todos)
DECLARE @BONIFICACIONBASE  numeric(9,2) --   = (select   bonificacion_base  from #todos)
DECLARE @SALARIORECIBIDA  numeric(9,2)  --  = (select   sueldo_base_recibido  from #todos)
DECLARE @BONIFICACIONRECIBIDA  numeric(9,2) --   = (select bonificacion_base_recibido     from #todos)
DECLARE @EXTRAS numeric(9,2)  --  = (select   total_extras  from #todos)
DECLARE @INGRESOS numeric(9,2)    -- =0  -- (select   ingresos_afectos_prestaciones  from #todos)
--SET @INGRESOS = (SELECT  ISNULL(SUM( ingresos_afectos_prestaciones),0)  FROM pl.VW_PLANILLA  WHERE empleado_id =@IDEMPLEADO) /6
--select @ingresos

DECLARE @MONTOPERCIBIDO numeric(9,2) 
DECLARE @MONTODEVENGADO numeric(9,2)
DECLARE @DIARECIBIDO numeric(9,2)
DECLARE @DIADEVENGADO numeric(9,2)
declare @montomensual numeric (9,2)
declare @montodiario numeric(9,2)
declare @TOTALG numeric(9,2)
declare @diarioIN numeric(9,2)

set @montodiario= @montodiario + @INGRESOS
set @montomensual  = @montodiario  * @DIASMES 


declare @valorvacaciones  numeric(9,2)
declare @montodiariofin numeric(9,2)
--set  @montodiariofin = (select diario from pl.Empleado_Retiro_Detalle where rtrim(Tipo)='Indemizacion'
--           and Empleado_Retiro_Id = @IDRETIRO )
           
set  @montodiariofin = ISNULL( @montodiariofin,0)
if  @montodiariofin >0
begin
set @montodiario =@montodiariofin
end
---************  CONFIGURA CALCULO VACACION 1 = SI 0 =NO
---*********************************************************
declare @CALbonIndemizacion int=0      ---BONIFICACION****** 
declare @CALhorasIndemizacion int =1   ---HORAS EXTRAS******
declare @CALingresosIndemizacion int=1 ---INGRESOS**********
---*********************************************************
---*********************************************************
declare @CALmonto numeric (9,2) --out
exec pl.CalculoRetiroMONTO @idretiro, @CALbonIndemizacion, @CALhorasIndemizacion, @CALingresosIndemizacion, @CALmonto out
--select @CALmonto as monto, @montodiario
set @montodiario =@CALmonto



set @valorvacaciones = @montodiario *  @dias_vacaciones_paga  





declare @periodo int
set @periodo  = YEAR(@fechabaja) 

iNSERT INTO pl.Empleado_Retiro_Detalle
(Empleado_Retiro_Id,Periodo,SalarioBase,BonificacionBase,SalarioRecibido,BonificacionRecibida,Salario,Bonificacion
,Extras,IngresoAfectos,DoceBono,DoceAguinaldo,DiasLaborados,DiasDerecho,DiasGozados,Diario
,Valor,Tipo,created_at,created_by, monto, diarioCalculo, fecha_inicial, fecha_final)          

--select  from pl.Empleado_Retiro_Detalle 
select @IDRETIRO ,@periodo  as periodo, 
@SALARIOBASE  as SalarioBase, @BONIFICACIONBASE  AS BonificacionBase, 
@SALARIORECIBIDA  as SalarioRecibido, @BONIFICACIONRECIBIDA as BonificacionRecibida, 
@SALARIO as Salario, @BONIFICACIONBASE   as Bonificacion, @EXTRAS as Extras,
@INGRESOS as IngresosAfectos,  0 as Docebono, 0 as DoceAguin,
@DIASLABORADOS  as DiasLaborados, @dias_vacaciones_paga   as DiasDerecho, 0 as DiasGozados,
@montodiario   AS Diario, @valorvacaciones  AS Valor, 'Vacaciones',GETDATE(),  @USUARIO, @TOTALG , @diarioIN,
@fecha_inicio,@fecha_inicio  
 
end




--exec pl.CalculoRetiroVacaciones 49,''
select id, Valor,* from pl.Empleado_Retiro_Detalle  where Empleado_Retiro_Id =@idretiro and Tipo ='vacaciones'


GO
ALTER PROCEDURE  [pl].[CalculoRetiroSueldo]
(
@retiroid int,
@USUARIO varchar(50)
)
as


-- declare @retiroid int = 32
--declare  @USUARIO varchar(10) ='admin'


declare @ano int  = (select  year(fecha_retiro)  from pl.Empleado_Retiro  where id = @retiroid)
declare @mes  int = (select  MONTH(fecha_retiro)  from pl.Empleado_Retiro where id = @retiroid)
declare @empleadoProyectoid int = (select empleado_proyecto_id  from pl.Empleado_Retiro where id = @retiroid)
declare  @empleado_id int  = (select empleado_id  from pl.Empleado_Retiro where id = @retiroid)
declare @proyecto_id int  = (select proyecto_id from rh.Empleado_Proyecto  where id = @empleadoProyectoid )
declare @tipo_planilla_id int  = (select tipo_planilla_id  from rh.Empleado_Proyecto  where id = @empleadoProyectoid  )
declare @fechacontrato date = (select  fecha_retiro  from pl.Empleado_Retiro where id = @retiroid )


declare @empleado_porcentaje numeric(9,2) =(select empleado_porcentaje from cat.Tipo_ss  ss  inner join rh.Tipo_Planilla t on ss.id = t.tipo_ss_id  where t.id = @tipo_planilla_id )		
declare @patrono_porcentaje numeric(9,2) =(select patrono_porcentaje  from cat.Tipo_ss  ss  inner join rh.Tipo_Planilla t on ss.id = t.tipo_ss_id  where t.id = @tipo_planilla_id )				
declare @intecap_porcentaje  numeric(9,2)=(select intecap_porcentaje  from cat.Tipo_ss  ss  inner join rh.Tipo_Planilla t on ss.id = t.tipo_ss_id  where t.id = @tipo_planilla_id )				
declare @irtra_porcentaje numeric(9,2)	=(select irtra_porcentaje  from cat.Tipo_ss  ss  inner join rh.Tipo_Planilla t on ss.id = t.tipo_ss_id  where t.id = @tipo_planilla_id )			
 --select tipo_ss_id  from rh.Tipo_Planilla  
declare @diasbase int =30
declare @dias_calendario int=30
declare @horas_en_dia int =8
declare @anof varchar(4) = rtrim(@ano)
declare @mesf varchar(2) = rtrim(@mes)
if (LEN(@mes)=1)
begin
set @mesf = '0'+RTRIM(@mes)
end
declare @fechaini varchar(10) = @anof + rtrim(@mesf)+'01'  
declare @fechafin date =DATEADD(day,-1,( DATEADD(month,1,@fechaini)))
DECLARE @DiasLaborales numeric(9,2)
-- empieza el primero son 15 duas 
set @DiasLaborales = @diasbase

set @DiasLaborales =30
--if @diasbase =30 or @diasbase  = 31
--begin
--set @DiasLaborales=  (select DATEDIFF(day,@fechaini ,@fechafin ) +1)
--end
--select @fechaini, @fechafin, @DiasLaborales

--- VARIABLES PARA  CALCULO POR EMPLEADO
DECLARE @dias_ausencias numeric(9,2)
DECLARE @salario_base numeric(9,2) 
DECLARE @diascontrato numeric(9,2)
DECLARE @salario numeric(9,2)
DECLARE @dias_laborados numeric(9,2)
DECLARE @sueldo_base_recibido numeric(9,2)
DECLARE @bonificacionbase  numeric(9,2)
DECLARE @bonificacion_base_recibido numeric(9,2)
DECLARE @idcontrato int
DECLARE @ingresos_ss  numeric(9,2) =0
DECLARE @ingresos_no_ss  numeric(9,2) =0
DECLARE @ingresos_isr numeric(9,2) =0
DECLARE @ingresos_no_isr numeric(9,2) =0
DECLARE @ingresos_afectos_prestaciones numeric(9,2) =0 
DECLARE @ingresos_no_afectos_prestaciones numeric(9,2) =0  
DECLARE @descuento_ss  numeric(9,2) =0
DECLARE @descuentos_no_ss  numeric(9,2) =0
DECLARE @descuentos_isr numeric(9,2) =0
DECLARE @descuentos_no_isr numeric(9,2) =0
DECLARE @descuento_anticipo_quincena numeric(9,2) =0
DECLARE @cant_extras_simples  numeric(9,2)=0
DECLARE @monto_extras_simples numeric(9,2)  =0
DECLARE @cant_extras_dobles  numeric(9,2) =0
DECLARE @monto_extras_dobles numeric(9,2)=0
DECLARE @cant_extras_extendidas numeric(9,2)=0
DECLARE @monto_extras_extendidas numeric(9,2)=0
DECLARE @total_ingresos   numeric(9,2) =0
DECLARE @total_descuentos  numeric(9,2) =0
DECLARE @total_extras  numeric(9,2) =0
DECLARE @total_sueldo_liquido  numeric(9,2) =0
DECLARE @isr numeric(9,2)  =0
DECLARE @planilla_resumen_id int 
DECLARE @MONTO_SEPTIMOS numeric(9,2) =0
DECLARE @SEPTIMOS_OBTENIDOS numeric(8,2)  =0
DECLARE @Idanticipocabecera  numeric(9,2)  =0
DECLARE @usaantiquince int
DECLARE @diaslaboradosCalend numeric(8,2)  =0
set @descuento_anticipo_quincena = 0  
declare @diasvacaiones numeric(9,2) =0
------------SEPTIMOS OBTENIDOS  ------ LLENAR VARIABLE-------------
------------------------------
------------------------------------------------------------------

set @idcontrato = (select  id  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                    and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)


--ausencias
EXEC pl.DiasAusencia @fechaini ,@fechafin ,@horas_en_dia,  @empleado_id, @proyecto_id,   @dias_ausencias OUT
EXEC pl.DiasVacaciones @fechaini ,@fechafin ,@horas_en_dia,  @empleado_id, @proyecto_id,   @diasvacaiones OUT
--set @dias_ausencias = 6
--contratacion  verificar fecha de contrato
set @diascontrato  = DATEDIFF(day,@fechacontrato, @fechafin) 
--select @diascontrato
--salario Base
EXEC pl.SalarioEmpleado @empleado_id,@proyecto_id ,@tipo_planilla_id ,@salario OUT
declare @salarioDiarioOk numeric(9,2)
exec pl.SalarioEmpleadoDiario @empleado_id,@proyecto_id ,@tipo_planilla_id ,@salarioDiarioOk OUT

-- bonificacion base
-- INSERTAR
SET @bonificacionbase = (select  isnull(bono_base,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)                   
declare @ValidoDiariobase  bit
set @ValidoDiariobase  =  (select  isnull(diariob,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)                   
declare @salarioReal numeric (9,2)
SET @salarioReal = (select  isnull(salario ,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)                   
declare @ValidoDiarioSueldo  bit
set @ValidoDiarioSueldo  =  (select  isnull(diario,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)                   
declare @bonificacionbaseReal numeric (9,2)
set @bonificacionbaseReal =@bonificacionbase 
DECLARE @dias_suspendidos numeric(9,2)
set @dias_suspendidos  = (select pl.funSuspension(@empleado_id,@tipo_planilla_id,@proyecto_id ,@fechaini,@fechafin))
-- dias laborados
declare @Dias_ajuste int =0
SET @dias_laborados  =  @DiasLaborales  - @diascontrato  - @dias_ausencias - @dias_suspendidos - @diasvacaiones  - @Dias_ajuste  
set @dias_laborados  = @dias_laborados +1
IF @dias_laborados < 0 
BEGIN
SET @dias_laborados = 0 
END

--sueldo ordinario
set @diaslaboradosCalend  = @dias_calendario  - @diascontrato - @dias_ausencias - @dias_suspendidos  
 -- ausencias septimos
declare @diasausemciaseptimo numeric(9,2)
--ausencias
EXEC pl.DiasAusenciaSeptimo @fechaini ,@fechafin ,@horas_en_dia,  @empleado_id, @proyecto_id,   @diasausemciaseptimo OUT
declare @diaslaboradosseptimos numeric (9,2)
set @diaslaboradosseptimos = @dias_calendario  - @diascontrato - @diasausemciaseptimo- @dias_suspendidos  
SET @sueldo_base_recibido  = (@salario/@DiasLaborales) *  (@dias_laborados) 
SET @bonificacion_base_recibido  = (@bonificacionbase/@dias_calendario) *  (@diaslaboradosCalend+1)
set @mes = month(@fechaini)
set @ano  = YEAR(@fechaini)
set @Idanticipocabecera  = (select  top 1 id  from pl.Planilla_Cabecera  where 
tipo_planilla_id  = @tipo_planilla_id and proyecto_id  = @proyecto_id  and anticipo = 1
and mes  =@mes and ano  = @ano
order by id desc ) 
set @Idanticipocabecera  = (ISNULL(@Idanticipocabecera, 0))
set @descuento_anticipo_quincena=  isnull((select pl.funTotalIngresos(@Idanticipocabecera, @empleado_id) ),0)
	

DECLARE @TotalIngresosAfectosSS numeric(9,2)
SET @TotalIngresosAfectosSS  = @sueldo_base_recibido +@bonificacion_base_recibido + @ingresos_ss +@MONTO_SEPTIMOS + @total_extras
DECLARE @SeguroSocialEmpleado  numeric(9,2) =0
DECLARE @SeguroSocialPatronal numeric(9,2)=0
DECLARE @irtra  numeric(9,2) =0
DECLARE @intecap numeric(9,2) =0



SET @SeguroSocialEmpleado  = (@TotalIngresosAfectosSS * @empleado_porcentaje)/100  
SET @SeguroSocialPatronal = (@TotalIngresosAfectosSS * @patrono_porcentaje )/100 
SET @irtra   = (@TotalIngresosAfectosSS * @irtra_porcentaje )/100  
SET @intecap  = (@TotalIngresosAfectosSS * @intecap_porcentaje  )/100
	
--select @dias_laborados, @sueldo_base_recibido, @bonificacion_base_recibido,
--@descuento_anticipo_quincena,@TotalIngresosAfectosSS,@SeguroSocialEmpleado

set  @SeguroSocialEmpleado  = (@sueldo_base_recibido *4.83)/100
declare @totalg numeric(9,2)

delete from  pl.Empleado_Retiro_detalle  where Empleado_Retiro_Id  = @retiroid
and Tipo ='Sueldo'
set @totalg =(@sueldo_base_recibido+ @bonificacion_base_recibido-@descuento_anticipo_quincena -@SeguroSocialEmpleado)

--set @totalg = @SeguroSocialEmpleado
-- set @totalg = @DiasLaborales
set @salario_base = @salarioDiarioOk *30


if @dias_laborados <30
begin

declare @existe int 
set @existe =(select   COUNT(*)   from pl.Planilla_Cabecera  c
inner join pl.Planilla_Resumen r 
on c.id = r.planilla_cabecera_id 
where empleado_id =@empleado_id
and fecha_inicio <=  @fechacontrato and fecha_fin  >=@fechacontrato)
if (@existe =0)
begin

iNSERT INTO pl.Empleado_Retiro_Detalle
(Empleado_Retiro_Id,Periodo,SalarioBase,BonificacionBase,SalarioRecibido,BonificacionRecibida,Salario,Bonificacion
,Extras,IngresoAfectos,DoceBono,DoceAguinaldo,DiasLaborados,DiasDerecho,DiasGozados,Diario
,Valor,Tipo,created_at,created_by, monto, diarioCalculo, fecha_inicial, fecha_final)          
--@TotalIngresosAfectosSS

select @retiroid ,@ano   as periodo, 
@salario_base as SalarioBase, @BONIFICACIONBASE  AS BonificacionBase, 
@sueldo_base_recibido  as SalarioRecibido, @bonificacion_base_recibido as BonificacionRecibida, 
@SALARIO as Salario, @bonificacionbase  as Bonificacion, 0 as Extras,
0 as IngresosAfectos, 0 as Docebono, 0  as DoceAguin,
@dias_laborados as DiasLaborados, @dias_laborados   as DiasDerecho, 0 as DiasGozados,
@salarioDiarioOk   AS Diario, @totalg AS Valor, 'Sueldo',GETDATE(), 
  @USUARIO, @TOTALG , @salarioDiarioOk,  
 @fechaini,@fechafin 
end
end
--select * from pl.Empleado_Retiro_Detalle

GO


--GO
ALTER PROCEDURE  [pl].[CalculoRetiroIndemizacion]
(
@IDRETIRO int,
@USUARIO varchar(50)
)
as
----set @IDRETIRO = 5 
BEGIN




CREATE TABLE  #HISTORIO  (empleado_id int,fecha_inicio date, fecha_fin date, dias_base numeric(9,2),dias_laborados numeric(9,2), sueldo_base numeric(9,2),
bonificacion_base numeric(9,2), sueldo_base_recibido numeric(9,2),bonificacion_base_recibido numeric(9,2), ingresos_afectos_prestaciones numeric(9,2),total_extras numeric(9,2))


-- DETALLE VARIABLES
DECLARE @DIASMES  int = 30
DECLARE @DIASPERIODO int = 365 
---*** DATOS DEL CALCULO DE RETIRO
select  proyecto_id, tipo_planilla_id,   calcular_base, metodo, porcentaje_indemizacion,
paga_indemizacion, bonificacion_indemizacion, horas_indemizacion,
ingresos_indemizacion, pl.empleado_id,fecha_alta, fecha_baja   into   #detalleEmpleado from  pl.Empleado_Retiro pl
inner join rh.Empleado_Proyecto  pr on pl.empleado_proyecto_id  = pr.id where pl.id = @IDRETIRO

--SELECT * FROM #detalleEmpleado
declare @IDEMPLEADO INT
declare @proyecto_id  int 
declare @tipo_planilla_id int
-- # POBLAR DATOS
declare @calcular_base varchar(100) -- ultimo sueldo  - promedio 
declare @metodo varchar(100) -- devengado percibido
declare @porcentaje_inde int
declare @paga_indemiza int
declare @bonIndemizacion int
declare @horasIndemizacion int
declare @ingresosIndemizacion int
declare @12VABONO numeric(9,2) 
declare @12VAGUIN  numeric(9,2)
declare @fechaalta date
declare @fechabaja date
---*** VARIABLES AFECTAN CALCULO VACACIONES
SET @IDEMPLEADO = (select  empleado_id from #detalleEmpleado )
SET @proyecto_id =(select proyecto_id from #detalleEmpleado )
SET @tipo_planilla_id =(select tipo_planilla_id from #detalleEmpleado )
SET @calcular_base = (select calcular_base from #detalleEmpleado )
SET @metodo = (select rtrim(metodo) from #detalleEmpleado )
SET @porcentaje_inde = (select porcentaje_indemizacion from #detalleEmpleado )
SET @paga_indemiza = (select paga_indemizacion from #detalleEmpleado )
SET @bonIndemizacion = (select bonificacion_indemizacion from #detalleEmpleado )
SET @horasIndemizacion = (select horas_indemizacion from #detalleEmpleado )
SET @ingresosIndemizacion =(select ingresos_indemizacion from #detalleEmpleado )
set @fechaalta  = (select   fecha_alta from #detalleEmpleado )
set @fechabaja  = (select fecha_baja from #detalleEmpleado)
--- ***     SETEO DE VARIABLES

set @horasIndemizacion = 0
set @ingresosIndemizacion =1
set @bonIndemizacion =0


drop table  #detalleEmpleado 

declare @DIAS_TOTAL_LABORADOS numeric(9,2)
DECLARE @NO_MESES INT
DECLARE @MES_FINAL DATE
--ELIMINAMOS REGISTRO ANTERIOR
delete from  pl.Empleado_Retiro_detalle  where Empleado_Retiro_Id  = @IDRETIRO and Tipo ='Indemizacion'
--****--- SALARIO BONIFICACION
declare @SALARIO numeric(9,2)
SET @SALARIO = (select top 1   isnull(salario,0)  from rh.Empleado_Proyecto  where empleado_id  = @IDEMPLEADO  and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id order by fecha_alta  desc)  -- and activo =1)     
declare @BONIFICACION numeric(9,2)
SET @BONIFICACION = (select top 1   isnull(bono_base,0)  from rh.Empleado_Proyecto  where empleado_id  = @IDEMPLEADO   and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id order by fecha_alta  desc)  -- and activo =1)     

set @DIAS_TOTAL_LABORADOS = (select  sum(dias_laborados)  from
pl.VW_PLANILLA 
--  pl.Planilla_Resumen r inner join  pl.Planilla_Cabecera c on c.id = r.planilla_cabecera_id  
where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id
and proyecto_id = @proyecto_id  and ISNULL(vacacion,0)=0 and bono=0 and aguinaldo =0  AND anticipo =0 )

set @NO_MESES =  (select  COUNT(*)  from 
pl.VW_PLANILLA 
-- pl.Planilla_Resumen r inner join  pl.Planilla_Cabecera c on c.id = r.planilla_cabecera_id  
where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id
and proyecto_id = @proyecto_id  and ISNULL(vacacion,0)=0 and bono=0 and aguinaldo =0  AND anticipo =0)

set @MES_FINAL =  (select  MAX(fecha_inicio)   from 
-- pl.Planilla_Resumen r inner join  pl.Planilla_Cabecera c on c.id = r.planilla_cabecera_id  
pl.VW_PLANILLA 
where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id
and proyecto_id = @proyecto_id  and ISNULL(vacacion,0)=0 and bono=0 and aguinaldo =0  AND anticipo =0)
print  ' CONTRATO ---------------------------------'
print  ' SALARIO '+rtrim(@SALARIO)+' BONIFICACION ' + RTRIM(@BONIFICACION) 
     + ' DIAS TOTAL LABORADOS ' + RTRIM(@DIAS_TOTAL_LABORADOS) + ' NUMERO PLANILLAS ' +RTRIM(@NO_MESES)
--select @SALARIO as Salario, @BONIFICACION as bonificacion, @DIAS_TOTAL_LABORADOS as dias
print  ' -------------------------------------------'
---** PARA LOS QUE NO TIENE 6 MESES 
if ((@calcular_base= 'Promedio Seis Meses' )  AND (@NO_MESES  >=6))    
BEGIN
PRINT ' OPCION DE HISTORICO *****PROMEDIO SEIS MESES' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )
select  empleado_id,  c.fecha_inicio , c.fecha_fin ,  sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados,  sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras
--  from pl.Planilla_Resumen  p inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
from pl.VW_PLANILLA  c
where empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
and c.activo = 0  and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0 and ISNULL(bono,0) = 0 
and dias_laborados > 0 
--and  fecha_inicio 
and fecha_inicio >= DATEADD (MONTH,-6, @MES_FINAL) 
group by empleado_id ,c.fecha_inicio , c.fecha_fin
order by c.fecha_inicio  desc 
END
if ((@calcular_base= 'Promedio Doce Meses' ) AND (@NO_MESES  >=12))    
BEGIN
PRINT ' OPCION DE HISTORICO  *****DOCE MESES' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )
select  empleado_id, fecha_inicio , fecha_fin ,  sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados,  sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras from 
--pl.Planilla_Resumen  p inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
pl.VW_PLANILLA 
where empleado_id  = @IDEMPLEADO  and proyecto_id  = @proyecto_id  
and tipo_planilla_id  = @tipo_planilla_id   and anticipo  = 0
and activo = 0  and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0 and ISNULL(bono,0) = 0 
and dias_laborados > 0 
and fecha_inicio >= DATEADD (MONTH,-12, @MES_FINAL) 
group by empleado_id ,fecha_inicio , fecha_fin
order by fecha_inicio  desc 
END
if   (SELECT COUNT(*) FROM #HISTORIO )   <= 6 AND (SELECT COUNT(*) FROM #HISTORIO )   >= 0 
BEGIN
PRINT ' OPCION DE HISTORICO  *****TODO SU HISTORICO' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )
select  empleado_id,  c.fecha_inicio , c.fecha_fin ,  
sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados, 
sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras from
-- pl.Planilla_Resumen  p  inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
pl.VW_PLANILLA  c
where empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
and c.activo = 0  and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0 and ISNULL(bono,0) = 0 
and dias_laborados > 0 
--and fecha_inicio >= DATEADD (MONTH,-6, @MES_FINAL) 
group by empleado_id ,c.fecha_inicio , c.fecha_fin
order by c.fecha_inicio  desc 
END

--select * from #HISTORIO
--declare @diava int
--set @diava = (
--select  c.dias_calendario  from rh.Tipo_Planilla  t  inner join cat.FrecuenciaPago c 
--on c.id = t.frecuencia_pago_id  where t.id = @tipo_planilla_id )

if   (SELECT COUNT(*) FROM #HISTORIO )   =0
BEGIN
PRINT ' OPCION DE HISTORICO  *****NO HAY HISTORICO' 
INSERT INTO #HISTORIO (empleado_id, fecha_inicio, fecha_fin, dias_base, dias_laborados,
sueldo_base , bonificacion_base , sueldo_base_recibido, bonificacion_base_recibido,
ingresos_afectos_prestaciones , total_extras )
select empleado_id , fecha_alta as fecha_inicio ,
fecha_alta as fecha_fin ,  30  as dias_base,30 as dias_laborados,
salario as sueldo_base, bono_base as bonificacion_base, salario  as sueldo_base_recibido,
bono_base as bonificacion_base_recibido, 0 as ingresos_afectos_prestaciones,
0 as total_extras    from rh.Empleado_Proyecto where empleado_id = @IDEMPLEADO
END



DECLARE @DIASLABORADOS numeric(9,2)= (select SUM(dias_laborados) from #HISTORIO)


DECLARE @DIARECIBIDO numeric(9,2) = (select   SUM(dias_laborados) from #HISTORIO)
--if (@metodo ='Percibido (Pagado Real)') 
--begin
--set @DIARECIBIDO=180
--end

DECLARE @DIADEVENGADO numeric(9,2) = (select   SUM(dias_base) from #HISTORIO)


DECLARE @DIASBASE numeric(9,2)= (select   SUM(dias_base) from #HISTORIO)
DECLARE @SALARIOBASE numeric(9,2)  = (select   sum(sueldo_base)  from #HISTORIO)
DECLARE @BONIFICACIONBASE  numeric(9,2)  = (select   sum(bonificacion_base)  from #HISTORIO)
DECLARE @SALARIORECIBIDA  numeric(9,2)  = (select   sum(sueldo_base_recibido)  from #HISTORIO)
DECLARE @BONIFICACIONRECIBIDA  numeric(9,2)  = (select sum(bonificacion_base_recibido)     from #HISTORIO)
DECLARE @EXTRAS numeric(9,2)  = (select   sum(total_extras)  from #HISTORIO)

DECLARE @EXTRASPROMEDIO numeric(9,2)  = (select   sum(total_extras) / SUM(dias_base)  from #HISTORIO)
SET  @EXTRASPROMEDIO  = @EXTRASPROMEDIO *30
DECLARE @INGRESOS numeric(9,2)  = (select   sum(ingresos_afectos_prestaciones)  from #HISTORIO)
SET @INGRESOS = (SELECT  ISNULL(SUM( ingresos_afectos_prestaciones),0)  FROM 
--PL.Planilla_Resumen 
pl.VW_PLANILLA  WHERE empleado_id =@IDEMPLEADO)

DECLARE @MONTOPERCIBIDO numeric(9,2) 
DECLARE @MONTODEVENGADO numeric(9,2)
DECLARE @MONTOBONIFI numeric(9,2)
declare @montomensual numeric (9,2)
declare @montodiario numeric(9,2)
declare @montoDiarioUnico numeric(9,2)
declare @TOTALG numeric(9,2)
declare @diarioIN numeric(9,2)
DECLARE @DIATOTAL numeric(9,2)
set @MONTOPERCIBIDO =  @SALARIORECIBIDA   
set @MONTODEVENGADO  = @SALARIOBASE
if @DIASLABORADOS  =0
BEGIN
SET @DIASLABORADOS =1
END
DECLARE @diasderecho numeric(9,2)
set @diasderecho  = ( select pl.funDiasComerciales(@fechaalta, @fechabaja))  +1 
set @diasderecho  = ( select datediff(day,@fechaalta, @fechabaja))  +1 
select @diasderecho, @fechaalta, @fechabaja
print  'DIAS DERECHO --------------------------------------------'
print 'dias total derecho  ' + rtrim(@diasderecho)
print '----------------------------------------------'

if RTRIM(@metodo)  = 'Percibido (Pagado Real)'
BEGIN

PRINT  ' PROMEDIO  ' + RTRIM((@INGRESOS / @DIADEVENGADO )  * @DIASMES)
set @TOTALG  = @MONTOPERCIBIDO 

select @MONTOPERCIBIDO as Monto, @DIARECIBIDO  as diaslaorados, @DIADEVENGADO as diasdev
-- SET  @DIATOTAL = @DIARECIBIDO
set @DIATOTAL = @DIADEVENGADO
set @MONTOBONIFI  = @BONIFICACIONBASE 
END
ELSE
BEGIN
set @TOTALG  = @MONTODEVENGADO 
SET  @DIATOTAL = @DIADEVENGADO 
set @MONTOBONIFI  = @BONIFICACIONRECIBIDA 
END
PRINT  '-----------  DETALLE DE CALCULO ---------'

drop table #HISTORIO
DECLARE @PROMEDIOMENSUAL numeric(9,2)
set  @PROMEDIOMENSUAL= (@TOTALG /@DIATOTAL ) *@DIASMES
if @ingresosIndemizacion =1
begin
PRINT  '-----------APLICA INGRESOS---------'
set  @PROMEDIOMENSUAL=  ((@INGRESOS /@DIATOTAL ) *@DIASMES) +@PROMEDIOMENSUAL
end
--SET @12VABONO = @PROMEDIOMENSUAL/12
--SET @12VAGUIN = @PROMEDIOMENSUAL/12
if @bonIndemizacion =1
begin
PRINT  '-----------APLICA BONIFICACION---------'
set  @PROMEDIOMENSUAL=  ((@MONTOBONIFI /@DIATOTAL ) *@DIASMES) +@PROMEDIOMENSUAL
end
if @bonIndemizacion =1
begin
PRINT  '-----------APLICA EXTRAS---------'
set  @PROMEDIOMENSUAL=  ((@EXTRAS/@DIATOTAL)  *@DIASMES ) +@PROMEDIOMENSUAL
end

SET @montodiario = @PROMEDIOMENSUAL/@DIASMES


---************  CONFIGURA CALCULO INDEMIZACION 1 = SI 0 =NO
---*********************************************************
declare @CALbonIndemizacion int=0      ---BONIFICACION****** 
declare @CALhorasIndemizacion int =1   ---HORAS EXTRAS******
declare @CALingresosIndemizacion int=1 ---INGRESOS**********
---*********************************************************
---*********************************************************
declare @CALmonto numeric (9,2) --out
exec pl.CalculoRetiroMONTO @idretiro, @CALbonIndemizacion, @CALhorasIndemizacion, @CALingresosIndemizacion, @CALmonto out
--select @CALmonto as monto, @montodiario

declare @CALmontoDoce numeric (9,2) --out
exec pl.CalculoRetiroMONTO @idretiro, 0, 0,0, @CALmontoDoce out
set @CALmontoDoce = @CALmontoDoce * @DIASMES

set @montodiario =@CALmonto

select @montodiario as diario

set @PROMEDIOMENSUAL = @montodiario *@DIASMES
set @12VABONO = @CALmontoDoce /12
set @12VAGUIN = @CALmontoDoce /12
select @CALmontoDoce as montodo,  @12VABONO as docebono
--select @DIASPERIODO, @diasderecho
declare @valorindemizacion  numeric(9,2)
SET @valorindemizacion= ((@PROMEDIOMENSUAL + @12VABONO+ @12VAGUIN) * @diasderecho)/@DIASPERIODO
select @PROMEDIOMENSUAL + @12VABONO+ @12VAGUIN as con12vos, @PROMEDIOMENSUAL  as Sin12



if @paga_indemiza  =0 
begin
SET @valorindemizacion= 0
end



set @INGRESOS= (@INGRESOS / @DIADEVENGADO )  * @DIASMES


declare @periodo int
set @periodo  = YEAR(@fechabaja) 

iNSERT INTO pl.Empleado_Retiro_Detalle
(Empleado_Retiro_Id,Periodo,SalarioBase,BonificacionBase,SalarioRecibido,BonificacionRecibida,Salario,Bonificacion
,Extras,IngresoAfectos,DoceBono,DoceAguinaldo,DiasLaborados,DiasDerecho,DiasGozados,Diario
,Valor,Tipo,created_at,created_by, monto, diarioCalculo, fecha_inicial, fecha_final)          

--select  from pl.Empleado_Retiro_Detalle 
select @IDRETIRO ,@periodo  as periodo, 
@SALARIOBASE  as SalarioBase, @BONIFICACIONBASE  AS BonificacionBase, 
@SALARIORECIBIDA  as SalarioRecibido, @BONIFICACIONRECIBIDA as BonificacionRecibida, 
@SALARIO as Salario, @BONIFICACION  as Bonificacion, @EXTRASPROMEDIO  as Extras,
@INGRESOS as IngresosAfectos,  @12VABONO as Docebono, @12VAGUIN  as DoceAguin,
@diasderecho as DiasLaborados, @diasderecho   as DiasDerecho, 0 as DiasGozados,
@montodiario   AS Diario, @VALORINDEMIZACION  AS Valor, 'Indemizacion',GETDATE(), 
  @USUARIO, @TOTALG , @montodiario,  
 @fechaalta,@fechabaja  
 

SELECT @valorindemizacion

----select  * from pl.Empleado_Retiro_Detalle  where Empleado_Retiro_Id = @IDRETIRO and Tipo = 'Indemizacion'

end



GO


ALTER PROCEDURE  [pl].[CalculoRetiroBono14]  --'33', 'admin'
(
@IDRETIRO int,
@USUARIO varchar(50)
)
as
BEGIN

DECLARE @DIASMES  numeric(9,2) = 30.0
DECLARE @DIASPERIODO int = 365
DECLARE @TIPODEVENGADO BIT =1
--DECLARE @IDRETIRO  INT
--SET @IDRETIRO = 21
--declare @USUARIO varchar(40)


-- consulta de datos
select  fecha_alta, proyecto_id, tipo_planilla_id,   calcular_base, metodo, porcentaje_indemizacion,
paga_indemizacion, bonificacion_bono , horas_bono ,paga_bonoAguinaldo,
ingresos_bono , pl.empleado_id,fecha_baja into   #detalleEmpleado from  pl.Empleado_Retiro pl
inner join rh.Empleado_Proyecto  pr on pl.empleado_proyecto_id  = pr.id where pl.id = @IDRETIRO

-- poblar datos
declare @IDEMPLEADO INT
declare @proyecto_id  int 
declare @tipo_planilla_id int
declare @calcular_base varchar(100) -- ultimo sueldo  - promedio 
declare @metodo varchar(100) -- devengado percibido
declare @bonBono int
declare @horasBono int
declare @ingresosBono int
declare @fecha_alta date = (select fecha_alta from #detalleEmpleado )
declare @fecha_baja date = (select fecha_baja from #detalleEmpleado )
SET  @calcular_base = (select calcular_base from #detalleEmpleado )
SET @metodo = (select metodo from #detalleEmpleado )
SET @bonBono  = (select bonificacion_bono from #detalleEmpleado )
SET @horasBono  = (select horas_bono from #detalleEmpleado )
SET @ingresosBono  =(select ingresos_bono from #detalleEmpleado )
SET @IDEMPLEADO = (select  empleado_id from #detalleEmpleado )
SET @proyecto_id =(select proyecto_id from #detalleEmpleado )
declare @paga_bonoAguinaldo int
SET @paga_bonoAguinaldo  =(select paga_bonoAguinaldo from #detalleEmpleado )

SET @tipo_planilla_id =(select tipo_planilla_id from #detalleEmpleado )
drop table #detalleEmpleado
-- fin de poblar datos


-- ultima planilla
select top 1 mes, ano  into #temp  from 

-- pl.Planilla_Cabecera  c  inner join pl.Planilla_Resumen  r on c.id = r.planilla_cabecera_id 
pl.VW_PLANILLA 
where tipo_planilla_id  = @tipo_planilla_id  and empleado_id  = @IDEMPLEADO 
and proyecto_id  = @proyecto_id  and anticipo  = 0 and activo = 0 
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 
order by fecha_inicio  desc 


DECLARE @MES INT
DECLARE @ANO INT
DECLARE @ANOANTERIOR INT
DECLARE @SIGUIENTEANO INT
SET @MES  =  (select  mes from #temp )
SET @ANO =  (select  ano  from #temp  ) 
SET @ANOANTERIOR  = @ANO -1
SET @SIGUIENTEANO = @ANO+1
drop table #temp

DECLARE @INICIOBONO varchar(10)
DECLARE @FINBONO varchar(10)
if @MES  <8
BEGIN
      SET @INICIOBONO  =rtrim(@ANOANTERIOR) +'0701'
      SET @FINBONO  = rtrim(@ANO)+'0630' 
 END
ELSE
BEGIN
      SET @INICIOBONO  =rtrim(@ANO)+'0701' 
       SET @FINBONO  = rtrim(@SIGUIENTEANO) +'0630'
END
--select @INICIOBONO as inicio, @FINBONO as fin  
  
 declare @fechacalculo varchar(10)  = @INICIOBONO

 declare @fecha varchar(10) = (select CONVERT(varchar(10), @fecha_alta ,112))
declare @fecha2 varchar(10) = (select CONVERT(varchar(10), @fecha_baja ,112))

   if @fecha_baja <@FINBONO
begin
set @FINBONO = @fecha_baja 
 end

   if @INICIOBONO  > @fecha 
 begin
set @INICIOBONO  = @fecha 
 end

declare @diaspendientes int
declare @valordiario numeric(9,2)

declare  @fechaba date
set @fechaba = (                 
select  top 1  REPLACE(CONVERT(varchar(10), fecha_retiro, 102),'.','-')   from pl.Empleado_Retiro
  where empleado_id = @IDEMPLEADO   order by id desc)
 
set @fechaba = ISNULL(@fechaba,'')
if @fechaba <> ''
begin
set @FINBONO = @fechaba
end



declare  @fechaini date
set @fechaini = (                 
select  top 1  REPLACE(CONVERT(varchar(10), fecha_alta, 102),'.','-')   from rh.Empleado_Proyecto 
  where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id  order by id desc)
 
set @fechaini = ISNULL(@fechaini,'')
if @fechaini <> ''
begin

if (@fechaini > @fechacalculo)
begin
set @fechacalculo = @fechaini
end
end




set @diaspendientes =( select pl.funDiasComerciales(@fechacalculo , @FINBONO ))+2
set @diaspendientes =(select DATEDIFF(day, @fechacalculo, @FINBONO)+1)

DECLARE @DIASLABORADOSR numeric(9,2) --= (select   dias_laborados  from #todos)
DECLARE @cantidad INT --= (select cantidad from #todos)
DECLARE @DIASBASE numeric(9,2)  --= (select   dias_base from #todos)
DECLARE @SALARIOBASE numeric(9,2) -- = (select   sueldo_base  from #todos)

if @DIASBASE =15
BEGIN
SET @DIASBASE = 30
END
declare @montoaguinaldo numeric(12,4)

-- SET @montoaguinaldo = @montoaguinaldo  * @diaspendientes 
--set @SALARIOBASE = (select diario  from pl.Empleado_Retiro_Detalle where rtrim(Tipo)='Indemizacion'  and Empleado_Retiro_Id = @IDRETIRO )

---************  CONFIGURA CALCULO BONO 14   1 = SI 0 =NO
---*********************************************************
declare @CALbonIndemizacion int=0      ---BONIFICACION****** 
declare @CALhorasIndemizacion int =0   ---HORAS EXTRAS******
declare @CALingresosIndemizacion int=1 ---INGRESOS**********
---*********************************************************
---*********************************************************
declare @CALmonto numeric (9,2) --out
exec pl.CalculoRetiroMONTO @idretiro, @CALbonIndemizacion, @CALhorasIndemizacion, @CALingresosIndemizacion, @CALmonto out
--select @CALmonto as monto, @montodiario
set @SALARIOBASE =@CALmonto




  delete from  pl.Empleado_Retiro_detalle  where Empleado_Retiro_Id  = @IDRETIRO and Tipo ='Bono14'
  declare @periodo int
   set @periodo  = DATEPART(year,@INICIOBONO  )
    INSERT INTO pl.Empleado_Retiro_Detalle
      (Empleado_Retiro_Id,Periodo,SalarioBase,BonificacionBase,SalarioRecibido,BonificacionRecibida,Salario,Bonificacion
      ,Extras,IngresoAfectos,DoceBono,DoceAguinaldo,DiasLaborados,DiasDerecho,DiasGozados,Diario,Valor,Tipo,
      created_at,created_by, monto, diarioCalculo, fecha_inicial, fecha_final)   
 select Empleado_Retiro_Id, @periodo, SalarioBase, BonificacionBase,
   SalarioRecibido, BonificacionRecibida, Salario, Bonificacion, Extras, IngresoAfectos,
   0, 0, @diaspendientes, @diaspendientes, 0, @valordiario, 
   --cast(((@INGRESOS  + ((@SALARIOBASE/ @DIASBASE )*30) )/365) * @diaspendientes  as numeric(9,2)) ,
   --(@SALARIOBASE /365) *@diaspendientes, 
   ((@SALARIOBASE *30)/365)*	@diaspendientes,

   'Bono14' ,
       GETDATE(), @USUARIO, @montoaguinaldo, @valordiario, @INICIOBONO, @FINBONO 
           from pl.Empleado_Retiro_Detalle where rtrim(Tipo)='Indemizacion'
           and Empleado_Retiro_Id = @IDRETIRO 
--drop table #todos

select id, Valor,DiasDerecho from pl.Empleado_Retiro_Detalle where Empleado_Retiro_Id = @IDRETIRO
and Tipo ='bono14'

END



GO

ALTER  PROCEDURE  [pl].[CalculoRetiroAguinaldo] --'33', 'admin'
( 
@IDRETIRO int,
@USUARIO varchar(50)
)
as
BEGIN
DECLARE @DIASMES  numeric(9,2) = 30.00
DECLARE @DIASPERIODO int = 365
DECLARE @TIPODEVENGADO BIT =1
--DECLARE @IDRETIRO  INT
--SET @IDRETIRO = 18
-- consulta de datos
select fecha_alta , proyecto_id, tipo_planilla_id,   calcular_base, metodo, porcentaje_indemizacion,
paga_indemizacion, pl.empleado_id, fecha_baja,
ingresos_aguinaldo, horas_aguinaldo, bonificacion_aguinaldo,
paga_bonoAguinaldo
into   #detalleEmpleado from  pl.Empleado_Retiro pl
inner join rh.Empleado_Proyecto  pr on pl.empleado_proyecto_id  = pr.id where pl.id = @IDRETIRO
-- poblar datos
declare @IDEMPLEADO INT
declare @proyecto_id  int 
declare @tipo_planilla_id int
declare @calcular_base varchar(100) -- ultimo sueldo  - promedio 
declare @metodo varchar(100) -- devengado percibido
declare @bonAguinaldo int
declare @horasAguinaldo int
declare @ingresosAguinaldo int

declare @fecha_baja date = (select fecha_baja from #detalleEmpleado )
SET  @calcular_base = (select calcular_base from #detalleEmpleado )
SET @metodo = (select metodo from #detalleEmpleado )
SET @bonAguinaldo  = (select bonificacion_aguinaldo from #detalleEmpleado )
SET @horasAguinaldo  = (select horas_aguinaldo from #detalleEmpleado )
SET @ingresosAguinaldo  =(select ingresos_aguinaldo from #detalleEmpleado )
SET @IDEMPLEADO = (select  empleado_id from #detalleEmpleado )
SET @proyecto_id =(select proyecto_id from #detalleEmpleado )
SET @tipo_planilla_id =(select tipo_planilla_id from #detalleEmpleado )
declare @fecha_alta date = (select fecha_alta from #detalleEmpleado )
declare @paga_bonoAguinaldo int
SET @paga_bonoAguinaldo  =(select paga_bonoAguinaldo from #detalleEmpleado )
drop table #detalleEmpleado
-- fin de poblar datos

-- ultima planilla
select top 1 mes, ano  into #temp  from 
-- pl.Planilla_Cabecera  c  inner join pl.Planilla_Resumen  r on c.id = r.planilla_cabecera_id 
pl.VW_PLANILLA 
where tipo_planilla_id  = @tipo_planilla_id  and empleado_id  = @IDEMPLEADO 
and proyecto_id  = @proyecto_id  and anticipo  = 0 and activo = 0 
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 
order by fecha_inicio  desc 

DECLARE @MES INT
DECLARE @ANO INT
DECLARE @ANOANTERIOR INT
DECLARE @SIGUIENTEANO INT
SET @MES  =  (select  mes from #temp )
SET @ANO =  (select  ano  from #temp  ) 
 SET @ANOANTERIOR  = @ANO -1
SET @SIGUIENTEANO = @ANO+1
drop table #temp

DECLARE @INICIOAGUINALDO varchar(10)
DECLARE @FINAGUINALDO varchar(10) 
 SET @INICIOAGUINALDO  = rtrim(@ANOANTERIOR) +'1201'

declare @fechacalculo varchar(10)  = @INICIOAGUINALDO
-- select @INICIOAGUINALDO 
 SET @FINAGUINALDO  = rtrim(@ANO)+'1130' 
  ---select @INICIOAGUINALDO as inicio, @FINAGUINALDO as fin 
 declare @fecha varchar(10) = (select CONVERT(varchar(10), @fecha_alta ,112))
  declare @fecha2 varchar(10) = (select CONVERT(varchar(10), @fecha_baja ,112))

  if @fecha_baja <@FINAGUINALDO 
 begin
set @FINAGUINALDO  = @fecha_baja 
 end

   if @INICIOAGUINALDO   > @fecha 
 begin
set @INICIOAGUINALDO   = @fecha 
 end

declare @diaspendientes int
declare @valordiario numeric(12,4)=0

declare  @fechaba date
set @fechaba = (                 
select  top 1  REPLACE(CONVERT(varchar(10), fecha_retiro, 102),'.','-')   from pl.Empleado_Retiro
  where empleado_id = @IDEMPLEADO   order by id desc)

set @fechaba = ISNULL(@fechaba,'')
if @fechaba <> ''
begin
set @FINAGUINALDO = @fechaba
end



declare  @fechaini date
set @fechaini = (                 
select  top 1  REPLACE(CONVERT(varchar(10), fecha_alta, 102),'.','-')   from rh.Empleado_Proyecto 
  where empleado_id = @IDEMPLEADO and tipo_planilla_id = @tipo_planilla_id  order by id desc)

set @fechaini = ISNULL(@fechaini,'')
if @fechaini <> ''
begin
if (@fechaini > @fechacalculo)
begin
set @fechacalculo = @fechaini
end
end

--select @fechacalculo as fechacal , @FINAGUINALDO as finaguina
--set @diaspendientes =( select pl.funDiasComerciales(@fechacalculo , @FINAGUINALDO ))+2
set @diaspendientes =(select DATEDIFF(day, @fechacalculo, @FINAGUINALDO)+1)
-- sELECT @diaspendientes , @fechacalculo as inicio , @FINAGUINALDO  as fin

--[pl].[CalculoRetiroAguinaldo] '33', 'admin'


select @diaspendientes as diapendien




--*******************


DECLARE @DIASLABORADOS numeric(9,2) -- = (select   dias_laborados  from #todos)
DECLARE @cantidad INT -- = (select cantidad from #todos)
DECLARE @DIASBASE numeric(12,4) -- = (select   dias_base from #todos)

if @DIASBASE =15
BEGIN
SET @DIASBASE = 30
END
DECLARE @SALARIOBASE numeric(12,4) --  = (select   cast(sueldo_base as numeric(12,2))  from #todos)
DECLARE @BONIFICACIONBASE  numeric(9,2) --  = (select   bonificacion_base  from #todos)
DECLARE @SALARIORECIBIDA  numeric(9,2)  -- = (select   sueldo_base_recibido  from #todos)
DECLARE @BONIFICACIONRECIBIDA  numeric(9,2) --  = (select bonificacion_base_recibido     from #todos)
DECLARE @EXTRAS numeric(9,2)  -- = (select   total_extras  from #todos)
DECLARE @INGRESOS numeric(9,2) --  = (select   ingresos_afectos_prestaciones  from #todos)
--SET @INGRESOS = (SELECT  ISNULL(SUM( ingresos_afectos_prestaciones),0)  
--FROM PL.VW_PLANILLA   WHERE empleado_id =@IDEMPLEADO)



declare @montoaguinaldo numeric(12,4)




    
    
       delete from  pl.Empleado_Retiro_detalle  where Empleado_Retiro_Id  = @IDRETIRO and Tipo ='Aguinaldo'
   declare @periodo int
   set @periodo  = DATEPART(year,@INICIOAGUINALDO  )


--set @SALARIOBASE = (select diario  from pl.Empleado_Retiro_Detalle where rtrim(Tipo)='Indemizacion'
--           and Empleado_Retiro_Id = @IDRETIRO )


---************  CONFIGURA CALCULO AGUINALDO 1 = SI 0 =NO
---*********************************************************
declare @CALbonIndemizacion int=0      ---BONIFICACION****** 
declare @CALhorasIndemizacion int =0   ---HORAS EXTRAS******
declare @CALingresosIndemizacion int=1 ---INGRESOS**********
---*********************************************************
---*********************************************************
declare @CALmonto numeric (9,2) --out
exec pl.CalculoRetiroMONTO @idretiro, @CALbonIndemizacion, @CALhorasIndemizacion, @CALingresosIndemizacion, @CALmonto out
--select @CALmonto as monto, @montodiario
set @SALARIOBASE =@CALmonto



 
INSERT INTO pl.Empleado_Retiro_Detalle
      (Empleado_Retiro_Id,Periodo,SalarioBase,BonificacionBase,SalarioRecibido,BonificacionRecibida,Salario,Bonificacion
      ,Extras,IngresoAfectos,DoceBono,DoceAguinaldo,DiasLaborados,DiasDerecho,DiasGozados,Diario,Valor,Tipo,
      created_at,created_by, monto, diarioCalculo, fecha_inicial, fecha_final)     
 select Empleado_Retiro_Id, @periodo, @SALARIOBASE , @BONIFICACIONBASE ,
@SALARIORECIBIDA, @BONIFICACIONRECIBIDA , Salario, Bonificacion, @EXTRAS , @INGRESOS ,
  0, 0, @diaspendientes, @diaspendientes , 0, @valordiario, 
  --cast(((@INGRESOS  + ((@SALARIOBASE/ @DIASBASE ) )*30)/365) * @diaspendientes  as numeric(9,2)),
--(@SALARIOBASE /365) *@diaspendientes,
((@SALARIOBASE *30)/365)*	@diaspendientes,

  'Aguinaldo',
  
  GETDATE(), @USUARIO, @montoaguinaldo, @valordiario, @INICIOAGUINALDO, @FINAGUINALDO
  from pl.Empleado_Retiro_Detalle where  rtrim(Tipo)='Indemizacion'
  and Empleado_Retiro_Id = @IDRETIRO
  select id, Valor,DiasDerecho from pl.Empleado_Retiro_Detalle where Empleado_Retiro_Id = @IDRETIRO
and Tipo ='Aguinaldo'

  
 END



