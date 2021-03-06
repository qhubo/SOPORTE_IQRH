USE [grupoazur]
GO
/****** Object:  StoredProcedure [pl].[CalculoPlanillaEmpleadoInprolacsa]    Script Date: 07/11/2018 17:07:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [pl].[CalculoPlanillaEmpleadoInprolacsa] (
@planillacabecera int,
@empleado_id int,
@usuario varchar(32),
@tipo_planilla_id int,                        
@Es_Anticipo bit,                             
@porcentaje_anticipo numeric(9,2),      
@fechaini varchar(10),                        
@fechafin varchar(10),                        
@diasbase numeric(9,2),                                         
@horasdiarias numeric(9,2),                               
--@septimo int,                                     
@empleado_porcentaje numeric(9,2),      
@patrono_porcentaje numeric(9,2),       
@intecap_porcentaje  numeric(9,2),      
@irtra_porcentaje numeric(9,2)    ,           
@provision_aguinaldo numeric(9,2),      
@provision_bono14 numeric(9,2),               
@provision_indemizacion numeric(9,2),   
@provision_vacaciones numeric(9,2),           
@proyecto_id  int,
@dias_calendario numeric(9,2),
@usa_anticipo_seguro_social bit,
@usa_anticipo_bonificacion bit,
@calendario_comercial bit,
@Usa_Septimo bit,
@Dias_ajuste numeric(9,2),
@salario_diab bit
--@dias_septimo_planilla numeric(9,2),                       
)
as
BEGIN


if (@diasbase = 15 and  day(@fechaini)< 15)
begin
set @Es_Anticipo =1
end
declare @empleado_porcentaje2 numeric(9,2) =0
declare @patrono_porcentaje2 numeric(9,2) =0 
declare @intecap_porcentaje2  numeric(9,2) =0      
declare  @irtra_porcentaje2 numeric(9,2) =0
declare  @montoMaximoSeguro numeric(9,2) =0
declare  @montoMaximoSeguro2 numeric(9,2) =0


select s.id, s.empleado_porcentaje , s.patrono_porcentaje, 
s.intecap_porcentaje, s.irtra_porcentaje, monto_maximo  into #nuevo   from rh.Empleado_Proyecto t  inner join cat.Tipo_ss s
on s.id = t.tipo_ss_id  where 
( t.empleado_id = @empleado_id and t.proyecto_id = @proyecto_id
and t.tipo_planilla_id = @tipo_planilla_id and t.activo =1 )
or ( t.activo =0 and t.empleado_id = @empleado_id  and  fecha_baja > = @fechaini      and fecha_baja < =@fechafin  )
 

declare @idregistro varchar(10) =( select top 1 id  from #nuevo)

set @idregistro  = ISNULL(@idregistro,0)
if @idregistro >0
begin
set @empleado_porcentaje =( select top 1 empleado_porcentaje  from #nuevo)
set @patrono_porcentaje =( select top 1 patrono_porcentaje  from #nuevo)
set @intecap_porcentaje =( select top 1 intecap_porcentaje from #nuevo)
set  @irtra_porcentaje =( select top 1 irtra_porcentaje   from #nuevo)
set  @montoMaximoSeguro =( select top 1 monto_maximo   from #nuevo)
end
drop table #nuevo
--set @empleado_porcentaje=3

---*******   segundo porcentaje 

declare @tipo_ss_id2 int 
set @tipo_ss_id2 = (select tipo_ss_id2  from rh.Tipo_Planilla where id = @tipo_planilla_id)
set @tipo_ss_id2 = ISNULL(@tipo_ss_id2,0)
if @tipo_ss_id2 >0
begin
set @empleado_porcentaje2 =( select top 1 empleado_porcentaje  from cat.Tipo_ss where id= @tipo_ss_id2)
set @patrono_porcentaje2 =( select top 1 patrono_porcentaje  from cat.Tipo_ss where  id= @tipo_ss_id2)
set @intecap_porcentaje2 =( select top 1 intecap_porcentaje from cat.Tipo_ss where  id= @tipo_ss_id2)
set  @irtra_porcentaje2 =( select top 1 irtra_porcentaje   from cat.Tipo_ss where  id= @tipo_ss_id2)
set  @montoMaximoSeguro2 =( select top 1 monto_maximo   from cat.Tipo_ss where  id= @tipo_ss_id2)
end



set @montoMaximoSeguro = ISNULL(@montoMaximoSeguro,0)
set @montoMaximoSeguro2 = ISNULL(@montoMaximoSeguro2,0)

print  '---  empleado  ID ---------------------------'
print @empleado_id
print  '---------------------------------------------' 


declare @horas_en_dia numeric(9,2)
set @horas_en_dia  = @horasdiarias / @diasbase 


print 'dias base ' + rtrim(@diasbase)
print 'horas diarias '+ rtrim(@horasdiarias)
--DECLARE @planillacabecera int
--DECLARE @empleado_id int
--DECLARE @usuario varchar(32)
--SET @planillacabecera  = 22
--SET @empleado_id =1
--SET @usuario  =  'admin'

--#region CONSULTA PARA  PARAMETROS INICIALES
--select pl.tipo_planilla_id,  pl.anticipo as 'Es_Anticipo', t.porcentaje_anticipo, CONVERT(varchar(10), pl.fecha_inicio ,112) as inicio,
--CONVERT(varchar(10), pl.fecha_fin ,112)  as fin,fe.diasbase, fe.horasbase, fe.septimo, 
--ss.empleado_porcentaje,  ss.patrono_porcentaje,  ss.intecap_porcentaje, ss.irtra_porcentaje,  
--provision_aguinaldo, provision_bono14, provision_indemnizacion, provision_vacaciones, pl.proyecto_id 
--into  #tablaVariables  from rh.Tipo_Planilla  t 
--inner join pl.Planilla_Cabecera  pl on t.id = pl.tipo_planilla_id
--inner join cat.FrecuenciaPago  fe on fe.id = t.frecuencia_pago_id  
--inner join cat.Tipo_ss  ss on t.tipo_ss_id = ss.id  where pl.id = @planillacabecera   
----#region INICIALES PARA CALCULO
--declare @tipo_planilla_id int                            SET @tipo_planilla_id= (select tipo_planilla_id from #tablaVariables )
--declare @Es_Anticipo bit                                 SET @Es_Anticipo = (select Es_Anticipo from #tablaVariables )
--declare @porcentaje_anticipo numeric(9,2)          SET @porcentaje_anticipo = (select porcentaje_anticipo from #tablaVariables )
--declare @fechaini varchar(10)                            SET @fechaini = (select inicio from #tablaVariables )
--declare @fechafin varchar(10)                            SET @fechafin = (select fin from #tablaVariables )
--declare @diasbase int                                    SET @diasbase = (select diasbase from #tablaVariables )
--declare @horasdiarias int                                SET @horasdiarias = (select horasbase from #tablaVariables )
--declare @septimo int                                     SET @septimo = (select septimo from #tablaVariables )
--declare @empleado_porcentaje numeric(9,2)          SET @empleado_porcentaje = (select empleado_porcentaje from #tablaVariables )
--declare @patrono_porcentaje numeric(9,2)           SET @patrono_porcentaje = (select patrono_porcentaje from #tablaVariables )
--declare @intecap_porcentaje  numeric(9,2)          SET @intecap_porcentaje = (select intecap_porcentaje from #tablaVariables )
--declare @irtra_porcentaje numeric(9,2)             SET @irtra_porcentaje = (select irtra_porcentaje from #tablaVariables )
--declare @provision_aguinaldo numeric(9,2)          SET @provision_aguinaldo = (select provision_aguinaldo from #tablaVariables )
--declare @provision_bono14 numeric(9,2)             SET @provision_bono14 = (select provision_bono14 from #tablaVariables )
--declare @provision_indemizacion numeric(9,2) SET @provision_indemizacion = (select provision_indemnizacion from #tablaVariables )
--declare @provision_vacaciones numeric(9,2)         SET @provision_vacaciones = (select provision_vacaciones from #tablaVariables )
--declare @proyecto_id  int                       SET @proyecto_id = (select proyecto_id from #tablaVariables )
--drop table #tablaVariables
--DEPENDE DE HORARIO 
DECLARE @DiasLaborales numeric(9,2)

-- empieza el primero son 15 duas 
set @DiasLaborales = @diasbase


if @diasbase =30 or @diasbase  = 31
begin
if @calendario_comercial = 0
begin
set @DiasLaborales=  (select DATEDIFF(day,@fechaini ,@fechafin ) +1)
end
end
if @Es_Anticipo =1
begin
set @DiasLaborales =16 - DAY(@fechaini)
end


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
DECLARE @ingresos_ss  numeric(9,2)
DECLARE @ingresos_no_ss  numeric(9,2)
DECLARE @ingresos_isr numeric(9,2)
DECLARE @ingresos_no_isr numeric(9,2)
DECLARE @ingresos_afectos_prestaciones numeric(9,2) 
DECLARE @ingresos_no_afectos_prestaciones numeric(9,2)
DECLARE @descuento_ss  numeric(9,2)
DECLARE @descuentos_no_ss  numeric(9,2)
DECLARE @descuentos_isr numeric(9,2)
DECLARE @descuentos_no_isr numeric(9,2)
DECLARE @descuento_anticipo_quincena numeric(9,2) =0
DECLARE @cant_extras_simples  numeric(9,2)
DECLARE @monto_extras_simples numeric(9,2)
DECLARE @cant_extras_dobles  numeric(9,2)
DECLARE @monto_extras_dobles numeric(9,2)
DECLARE @cant_extras_extendidas numeric(9,2)
DECLARE @monto_extras_extendidas numeric(9,2)
DECLARE @total_ingresos   numeric(9,2)
DECLARE @total_descuentos  numeric(9,2)
DECLARE @total_extras  numeric(9,2)
DECLARE @total_sueldo_liquido  numeric(9,2)
DECLARE @isr numeric(9,2)
DECLARE @planilla_resumen_id int 
DECLARE @MONTO_SEPTIMOS numeric(9,2)
DECLARE @SEPTIMOS_OBTENIDOS numeric(8,2) 
DECLARE @Idanticipocabecera  numeric(9,2) 
DECLARE @usaantiquince int
DECLARE @diaslaboradosCalend numeric(8,2) 
set @descuento_anticipo_quincena = 0  
declare @diasvacaiones numeric(9,2)
------------SEPTIMOS OBTENIDOS  ------ LLENAR VARIABLE-------------
------------------------------
------------------------------------------------------------------

set @idcontrato = (select top 1  id  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                    and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id 
                    order by id desc  -- and activo =1
                    )
declare @diaBaja int = (select top 1 DAY(fecha_baja)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                    and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id 
                    order by id desc  -- and activo =1
                    )
                    set @diaBaja = ISNULL(@diaBaja,0)


--ausencias
EXEC pl.DiasAusencia @fechaini ,@fechafin ,@horas_en_dia,  @empleado_id, @proyecto_id,   @dias_ausencias OUT
--IF (@Es_Anticipo = 0)
--begin
EXEC pl.DiasVacaciones @fechaini ,@fechafin ,@horas_en_dia,  @empleado_id, @proyecto_id,   @diasvacaiones OUT
--end
set @diasvacaiones = ISNULL( @diasvacaiones,0)
--exec [pl].[DiasAusencia]  '20130701' , '20130715', @horas_en_dia, @empleado_id,@proyecto_id, @dias_ausencias OUT
--set @dias_ausencias = 6
--contratacion  verificar fecha de contrato
EXEC  pl.RestaContrato   @empleado_id, @tipo_planilla_id, @proyecto_id, @fechaini, @fechafin, @diascontrato OUT
--salario Base
EXEC pl.SalarioEmpleado @empleado_id,@proyecto_id ,@tipo_planilla_id ,@salario OUT


declare @salarioDiarioOk numeric(9,2)
exec pl.SalarioEmpleadoDiario @empleado_id,@proyecto_id ,@tipo_planilla_id ,@salarioDiarioOk OUT

-- bonificacion base
-- INSERTAR
SET @bonificacionbase = (select top 1  isnull(bono_base,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id 
                                 order by id desc
                                 -- and activo =1
                                 )                   
declare @ValidoDiariobase  bit
set @ValidoDiariobase  =  (select top 1  isnull(diariob,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id 
                                  order by id desc
                                  -- and activo =1
                                  )                   
declare @salarioReal numeric (9,2)
SET @salarioReal = (select top 1  isnull(salario ,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id 
                                 order by id desc
                                  -- and activo =1
                                  )                   
declare @ValidoDiarioSueldo  bit
set @ValidoDiarioSueldo  =  (select top 1  isnull(diario,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id 
                                 order by id desc
                                 -- and activo =1
                                 )                   


declare @bonificacionbaseReal numeric (9,2)
set @bonificacionbaseReal =@bonificacionbase 

if @ValidoDiariobase =1
begin
set @bonificacionbase  = @bonificacionbaseReal  * @DiasLaborales 
end

if @ValidoDiarioSueldo  =1
begin
set @salario   = @salarioReal  * @DiasLaborales
end


--if @empleado_id =8
--begin
--end

DECLARE @dias_suspendidos numeric(9,2)
set @dias_suspendidos  = (select pl.funSuspension(@empleado_id,@tipo_planilla_id,@proyecto_id ,@fechaini,@fechafin))
--if (@dias_suspendidos >0)
--begin
--set @dias_suspendidos = @dias_suspendidos -1
--end

-- dias laborados
SET @dias_laborados  =  @DiasLaborales  - @diascontrato  - @dias_ausencias - @dias_suspendidos - @diasvacaiones  - @Dias_ajuste  
if @dias_laborados  > @diasbase 
begin
set @dias_laborados = @diasbase
end

--if ((day(@fechaini) =16) and (@diaBaja=16))
--begin
--set @dias_laborados =0
--end

if @Usa_Septimo = 1
begin
--declare @dias numeric(9,2)
--declare @septimos numeric(9,2) 
--exec [pl].[DiasPlanillaCatorcenal] '20130601','20130614',26,2,2,@dias out, @septimos out
exec [pl].[DiasPlanillaCatorcenal]   @fechaini,@fechafin ,@empleado_id ,@proyecto_id ,@tipo_planilla_id ,@dias_laborados  out, @SEPTIMOS_OBTENIDOS out

--select @dias, @septimos 
end


IF @dias_laborados < 0 
BEGIN
SET @dias_laborados = 0 
END

if (@empleado_id =10)
begin
set @dias_laborados=1
end


--sueldo ordinario
set @diaslaboradosCalend  = @dias_calendario  - @diascontrato - @dias_ausencias - @dias_suspendidos  
 -- ausencias septimos
declare @diasausemciaseptimo numeric(9,2)
--ausencias
EXEC pl.DiasAusenciaSeptimo @fechaini ,@fechafin ,@horas_en_dia,  @empleado_id, @proyecto_id,   @diasausemciaseptimo OUT

--set @diasausemciaseptimo= 1.25
declare @diaslaboradosseptimos numeric (9,2)

set @diaslaboradosseptimos = @dias_calendario  - @diascontrato - @diasausemciaseptimo- @dias_suspendidos  
--set @diasausemciaseptimo = @diasausemciaseptimo

--*** EXECPCION IMPROLACSA
--IF (@Es_Anticipo = 1) and (@dias_laborados >5)
--BEGIN
--set @dias_laborados=15
--end

--set @dias_laborados =3

--EXECPCION NO PAGA EN QUINCENA RETIRO
IF (@Es_Anticipo = 1)
BEGIN
declare @retiro int =0
--set @retiro = (select COUNT(*) from rh.empleado_proyecto where empleado_id = @empleado_id
--and proyecto_id = @proyecto_id and activo=1 and fecha_baja >= @fechaini and fecha_baja < @fechafin)

--if @retiro >0
--begin
--set @dias_laborados =0
--end
END

--INSERTAR
-- calculo por dias
SET @sueldo_base_recibido  = (@salario/@DiasLaborales) *  (@dias_laborados) 
if @diasbase=15 and day(@fechaini) >15
begin
SET @sueldo_base_recibido  = (@salario/30) *  (@dias_laborados) 
end
--set @sueldo_base_recibido = @diasbase
--set @sueldo_base_recibido = @salario

--if (@Es_Anticipo=1 ) and (@diasvacaiones >0)
--begin
--SET @sueldo_base_recibido  = (@salario/30) *  (@dias_laborados) 
--end


IF (@Es_Anticipo = 1)
begin
declare @salarioimpro numeric (9,2)
set @salarioimpro = (select top 1 salario from rh.Empleado_Proyecto where proyecto_id = @proyecto_id and
tipo_planilla_id  = @tipo_planilla_id 
--and activo =1
 and empleado_id = @empleado_id order by id desc)

declare @ingreso int
--set @retiro = (select COUNT(*) from rh.empleado_proyecto where empleado_id = @empleado_id
--and proyecto_id = @proyecto_id and activo=1 and fecha_alta  >= @fechaini and fecha_alta <= @fechafin)

if @ingreso >0
begin

--- en anticipo
set @sueldo_base_recibido =(@salario * @dias_laborados +15) /30
set @sueldo_base_recibido  = (@salario * @porcentaje_anticipo ) /100
end

end


--sueldo bonificacionrecibida
--SET @bonificacion_base_recibido  = (@bonificacionbase/@DiasLaborales) *  (@dias_laborados )
--IF @dias_septimo_planilla >0
--BEGIN
IF (@Es_Anticipo = 0)
BEGIN
SET @bonificacion_base_recibido  = (@bonificacionbase/@dias_calendario) *  (@diaslaboradosCalend - @diasvacaiones )

if @diasbase=15 and day(@fechaini) >15
begin
SET @bonificacion_base_recibido   = (@bonificacionbase /30) *  (30 - @diasvacaiones-15-@diascontrato -@dias_ausencias -@dias_suspendidos) 
end

if @dias_laborados  > @diasbase 
begin
SET @bonificacion_base_recibido   = (@bonificacionbase /30) *  @diasbase
end




if ((day(@fechaini) =16) and (@diaBaja=16))
begin
set @bonificacion_base_recibido   = 0
end

if (@empleado_id =10)
begin
set @bonificacion_base_recibido   = (@bonificacionbase /30) * 1
--set @bonificacion_base_recibido=454545
end


--if (@diasvacaiones >0)
--begin

--declare @bonifianti numeric(9,2)
--set @bonifianti =(
--select bonificacion_base_recibido   from pl.Planilla_Cabecera  c inner join pl.Planilla_Resumen  re
--on c.id = re.planilla_cabecera_id  where MONTH(fecha_inicio) =MONTH(@fechaini ) and anticipo =1
--and empleado_id = @empleado_id )

--declare @bonifiVaca numeric(9,2)
--set @bonifiVaca = (
--select bonificacion_base_recibido    from pl.Planilla_Cabecera  c inner join pl.Planilla_Resumen  re
--on c.id = re.planilla_cabecera_id  where MONTH(fecha_inicio) =MONTH(@fechaini ) and vacacion  =1
--and empleado_id = @empleado_id )

--set @bonificacion_base_recibido = @bonificacionbase  - isnull(@bonifiVaca,0) - ISNULL( @bonifianti,0) 
----set @bonificacion_base_recibido =  isnull(@bonifianti ,0)  

--end
end
set @SEPTIMOS_OBTENIDOS = ISNULL(@SEPTIMOS_OBTENIDOS,0)


if @ValidoDiariobase = 1
begin

SET @bonificacion_base_recibido = @bonificacionbaseReal *  (@dias_laborados +@SEPTIMOS_OBTENIDOS)

end
--SET @bonificacion_base_recibido  =  4555
--END 
--SET @usa_anticipo_bonificacion =1
--set @usa_anticipo_bonificacion  =1
--select descripcion, usa_anticipo_bonificacion from rh.Tipo_Planilla

IF (@Es_Anticipo = 1)
BEGIN
if @ValidoDiariobase = 0
begin
--SET @sueldo_base_recibido  = 1111111
declare @porempleado numeric(9,2)
set @porempleado = (select top 1 porcentaje_anticipo from rh.empleado_proyecto where empleado_id = @empleado_id
and proyecto_id = @proyecto_id and activo=1)
set @porempleado =  isnull(@porempleado,0)
if @porempleado >0
begin
set @porcentaje_anticipo = @porempleado
end


-- en anticipo
SET @sueldo_base_recibido =  (@sueldo_base_recibido * @porcentaje_anticipo)/100
-- SET @sueldo_base_recibido =  @porcentaje_anticipo  -- (@sueldo_base_recibido )
--sET @sueldo_base_recibido =  @sueldo_base_recibido
end

if (@usa_anticipo_bonificacion =1) 
BEGIN
if @ValidoDiariobase = 0
begin
-- SET @bonificacion_base_recibido = (@bonificacionbase/@dias_calendario) * @dias_laborados --@diaslaboradosCalend

--SET @bonificacion_base_recibido = (@bonificacionbase/) * @dias_laborados --@diaslaboradosCalend
SET @bonificacion_base_recibido = (@bonificacionbase /15) * (@dias_laborados )
SET @bonificacion_base_recibido =  (@bonificacion_base_recibido * @porcentaje_anticipo)/100
--set @bonificacion_base_recibido = @dias_suspendidos
      --set @bonificacion_base_recibido = 111
end
END
ELSE
BEGIN
      SET @bonificacion_base_recibido = 0
END


IF @dias_laborados   <=0
BEGIN
      SET @bonificacion_base_recibido = 0
END
--set @bonificacion_base_recibido =(@bonificacionbase/@DiasLaborales) *  (@dias_laborados) 
END



if @salario_diab =1
begin
set  @sueldo_base_recibido = (@salarioDiarioOk * @dias_laborados )
end

----------- CAMBIO ***********************
--set @sueldo_base_recibido= (
--select sum( [Salario Base])   - sum([40% Anticipo]) from dbo.Marzo15 
-- where RTRIM(id) = @empleado_id
--)
--set @sueldo_base_recibido  = @sueldo_base_recibido - @bonificacion_base_recibido 
--set @sueldo_base_recibido= ( ISNULL(@sueldo_base_recibido,0))
---------------******************************

if ((day(@fechaini) =16) and (@diaBaja=16))
begin
set @bonificacion_base_recibido   = 0
end
if @dias_laborados  > @diasbase 
begin
SET @bonificacion_base_recibido   = (@bonificacionbase /30) *  15
end

--if (@empleado_id =175)
--begin
--set @bonificacion_base_recibido = (@bonificacionbase /30) *15
--end
--if (@empleado_id =180)
--begin
--set @bonificacion_base_recibido = (@bonificacionbase /30) *15
--end


set @bonificacion_base_recibido = (@bonificacionbase /30) * @dias_laborados

SET @salario_base  = @salario    
--INSERTAMOS DATOS INICIALES 
INSERT INTO pl.Planilla_Resumen( dias_base,sueldo_base,bonificacion_base,salario_base, planilla_cabecera_id,
empleado_id,empleado_proyecto_id,dias_laborados,dias_ausencias, observaciones, activo,created_by,updated_by,created_at,updated_at )
VALUES (@diasbase-@Dias_ajuste,  @salario, @bonificacionbase, @salario_base, @planillacabecera,
@empleado_id, @idcontrato , @dias_laborados, @dias_ausencias, '',1,@usuario,@usuario, GETDATE(), GETDATE() )
---OBTENEMOS ID DE LA TABLA CABECERA RESUMEN
SET @planilla_resumen_id = (select max(id) from  pl.Planilla_Resumen )
--CALCULO DE INGRESOS
set @cant_extras_simples = 0 
set @monto_extras_simples = 0 
set @cant_extras_dobles = 0 
set @monto_extras_dobles = 0 
set @cant_extras_extendidas = 0 
set @monto_extras_extendidas = 0
EXEC pl.CalculoHorasExtras  @proyecto_id, @tipo_planilla_id, @empleado_id, @fechaini, @fechafin, 
@cant_extras_simples OUT, @cant_extras_dobles OUT ,  @cant_extras_extendidas OUT, 
@monto_extras_simples OUT,  @monto_extras_dobles OUT, @monto_extras_extendidas OUT


if @monto_extras_simples   > 0
begin
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
            ,centro_costo,identificar,monto,debe, haber,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
            VALUES (@planilla_resumen_id,'Extras Simples','Extras Simples ' ,0,'',
            '','+',@monto_extras_simples   ,@monto_extras_simples  ,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
            1,2, 0, 0, 0, 1 )
            
end

if @monto_extras_dobles  > 0
begin
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
            ,centro_costo,identificar,monto,debe, haber,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
            VALUES (@planilla_resumen_id,'Extras Dobles','Extras Dobles ' ,0,'',
            '','+',@monto_extras_dobles    ,@monto_extras_dobles   ,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
            1,2, 0, 0, 0, 1 )
end

if @monto_extras_extendidas   > 0
begin
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
            ,centro_costo,identificar,monto,debe, haber,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
            VALUES (@planilla_resumen_id,'Extras Extendidas','Extras Extendidas ',0,'',
            '','+',@monto_extras_extendidas     ,@monto_extras_extendidas   ,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
            1,2, 0, 0, 0, 1 )

end





--TOTAL EXTRAS
set @total_extras  = @monto_extras_simples + @monto_extras_dobles + @monto_extras_extendidas  
declare @baseCalculoINg numeric (9,2)

set @baseCalculoINg = @total_extras + @salario

exec pl.ICIngreso_Detalle @planilla_resumen_id,@empleado_id, @tipo_planilla_id, @proyecto_id, @usuario ,  @fechafin , @Es_Anticipo, @diasbase,@dias_laborados,@baseCalculoINg


--INSERTA SUELDO EN DETALLE
   INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
      columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
      VALUES (@planilla_resumen_id,'Sueldo','Sueldo Ordinario',-1,'',
      '','+',@sueldo_base_recibido,0,@sueldo_base_recibido, 1,@usuario, @usuario,GETDATE(), GETDATE(),
      1,1, 0, 1, 0, 1 )
--INSERTAR BONIFICACION EN DETALLE
   INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
      columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
      VALUES (@planilla_resumen_id,'Bonificacion','Bonificacion Decreto',0,'',
      '','+',@bonificacion_base_recibido ,0,@bonificacion_base_recibido, 1,@usuario, @usuario,GETDATE(), GETDATE(),
      1,2, 0, 0, 0, 1 )

declare @ingresos_SEPTIMOS numeric(9,2)
-- DETALLE DE INGRESOS
select * into #teming from pl.Planilla_Detalle  where tipo = 'Ingreso'  and  planilla_resumen_id  = @planilla_resumen_id
set @ingresos_ss = (select isnull(SUM(monto),0) from #teming where afecta_ss=1)
set @ingresos_no_ss = (select isnull(SUM(monto),0) from #teming where afecta_ss=0)
set @ingresos_isr = (select isnull(SUM(monto),0) from #teming where afecta_isr=1)
set  @ingresos_no_isr = (select isnull(SUM(monto),0) from #teming where afecta_isr=0)
set @ingresos_afectos_prestaciones = (select isnull(SUM(monto),0) from #teming where afecta_prestacion=1)
set @ingresos_no_afectos_prestaciones = (select isnull(SUM(monto),0) from #teming where afecta_prestacion=0)
set @ingresos_SEPTIMOS = (select isnull(SUM(monto),0) from #teming where afecta_septimo=1)
set  @total_ingresos  = @ingresos_ss  + @ingresos_no_ss 
drop table #teming


declare @baseCalculo numeric (9,2)

set @baseCalculo = @salario + @ingresos_afectos_prestaciones
-- CALCULO DE DESCUENTOS 
exec pl.ICDescuento_Detalle  @planilla_resumen_id,@empleado_id, @tipo_planilla_id, @proyecto_id, @usuario , @fechafin, @Es_Anticipo, @baseCalculo
print '*********************************************************'
print 'Calculo Descuentos Empleado ' + rtrim(@empleado_id)
print 'pl.ICDescuento_Detalle '  + rtrim(@planilla_resumen_id)+','+ rtrim(@empleado_id)+ ','+ rtrim(@tipo_planilla_id) +','+ rtrim(@proyecto_id) +','+ rtrim(@usuario)  +','+ rtrim(@fechafin) +','+ rtrim(@Es_Anticipo) +',' + rtrim(@salario_base)
print '*********************************************************'



            
IF (@Es_Anticipo = 0)
BEGIN
      set @usaantiquince  = (select usa_anticipo_quincenal  from rh.Tipo_Planilla  where id = @tipo_planilla_id)
      if (@usaantiquince=1 and (@Es_Anticipo = 0))
      BEGIN
      declare @mes int
      declare @ano int
      set @mes = month(@fechaini)
      set @ano  = YEAR(@fechaini)
      set @Idanticipocabecera  = (select  top 1 id  from pl.Planilla_Cabecera  where 
      tipo_planilla_id  = @tipo_planilla_id and proyecto_id  = @proyecto_id  and anticipo = 1
      and mes  =@mes and ano  = @ano
      order by id desc ) 
      set @Idanticipocabecera  = (ISNULL(@Idanticipocabecera, 0))
      
      
    if @Idanticipocabecera  > 0 and @dias_laborados >=30
    begin
      --set @descuento_anticipo_quincena=  isnull((select pl.funSueldo(@Idanticipocabecera, @empleado_id) ),0)
      set @descuento_anticipo_quincena=  isnull((select pl.funTotalIngresos(@Idanticipocabecera, @empleado_id) ),0)
      
      

      --INSERTA ANTICIPO DE QUINCENA
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
      ,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
            VALUES (@planilla_resumen_id,'Anticipo','Anticipo de Quincena',0,'',
            '','-',@descuento_anticipo_quincena ,@descuento_anticipo_quincena,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
            1,2, 0, 0, 0, 1 )
            
            
      end
   
    END
     
            
END   


-- DETALLE DE DESCUENTOS
select * into #temdes from pl.Planilla_Detalle  where tipo = 'Descuento'  and  planilla_resumen_id  = @planilla_resumen_id
set @descuento_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=1)
set @descuento_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=1)


set @descuentos_no_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=0)
set @descuentos_isr  = (select isnull(SUM(monto),0) from #temdes where afecta_isr=1)
set  @descuentos_no_isr  = (select isnull(SUM(monto),0) from #temdes where afecta_isr=0)
--set @descuentos_no_ss  = 0
drop table #temdes
--ANTICIPO DE QUINCENA
--INSERTAR

-- HORAS EXTRAS
-- INSERTAR
--- CALCULO DE SEPTIMO
--SET @dias_laborados = 12
--SET @total_extras =123

--

if  @dias_laborados > 0
begin
EXEC pl.CalculoSeptimoContratoId @sueldo_base_recibido, @dias_laborados,@idcontrato,@total_extras,@ingresos_SEPTIMOS,  @SEPTIMOS_OBTENIDOS,@MONTO_SEPTIMOS OUT
end 
else
begin
set @MONTO_SEPTIMOS = ISNULL(@MONTO_SEPTIMOS,0)
end
--SET @MONTO_SEPTIMOS=12
      --INSERTA CALCULO SEGURO SOCIAL
      --set @MONTO_SEPTIMOS =0
      --set @MONTO_SEPTIMOS =450

      if @MONTO_SEPTIMOS > 0
      begin
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
            ,centro_costo,identificar,monto,debe, haber,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
            VALUES (@planilla_resumen_id,'Septimos','Pago de Septimo',0,'',
            '','+',@MONTO_SEPTIMOS  ,@MONTO_SEPTIMOS ,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
            1,2, 0, 1, 0, 1 )
   end            
      --- CALCULO DE SEGURO SOCIAL
DECLARE @TotalIngresosAfectosSS numeric(9,2)
declare @montovac numeric(9,2)=0
if @Es_Anticipo =0
begin
if (@diasvacaiones >0)
begin
--set @montovac  =  
--(select sueldo_base_recibido    from pl.Planilla_Cabecera  c inner join pl.Planilla_Resumen  re
--on c.id = re.planilla_cabecera_id  where MONTH(fecha_inicio) =MONTH(@fechaini ) and vacacion  =1
--and empleado_id = @empleado_id )

 set @montovac  = ISNULL(@montovac,0)
end
end



SET @TotalIngresosAfectosSS  = @sueldo_base_recibido + @ingresos_ss +@MONTO_SEPTIMOS + @total_extras +@montovac
SET @TotalIngresosAfectosSS  = @sueldo_base_recibido+ @ingresos_ss +@MONTO_SEPTIMOS+ @total_extras +@montovac

DECLARE @SeguroSocialEmpleado  numeric(9,2) =0
DECLARE @SeguroSocialPatronal numeric(9,2)=0
DECLARE @irtra  numeric(9,2) =0
DECLARE @intecap numeric(9,2) =0

DECLARE @SeguroSocialEmpleado2  numeric(9,2) =0
DECLARE @SeguroSocialPatronal2 numeric(9,2)=0
DECLARE @irtra2  numeric(9,2) =0
DECLARE @intecap2 numeric(9,2) =0

--set @usa_anticipo_seguro_social =1

IF not((@Es_Anticipo = 1) and (@usa_anticipo_seguro_social =0)) 
BEGIN
      SET @SeguroSocialEmpleado  = (@TotalIngresosAfectosSS * @empleado_porcentaje)/100  
      
       if @montoMaximoSeguro >0
      begin
      if @montoMaximoSeguro < @SeguroSocialEmpleado
      begin
      set @SeguroSocialEmpleado=@montoMaximoSeguro
      end
      
      end
      SET @SeguroSocialPatronal = (@TotalIngresosAfectosSS * @patrono_porcentaje )/100 
      SET @irtra   = (@TotalIngresosAfectosSS * @irtra_porcentaje )/100  
      SET @intecap  = (@TotalIngresosAfectosSS * @intecap_porcentaje  )/100 
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
      ,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
           VALUES (@planilla_resumen_id,'Seguro Social','Seguro Social Empleado',0,'',
            '','-',@SeguroSocialEmpleado ,@SeguroSocialEmpleado,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
            1,2, 0, 1, 0, 1 )
            
            --*** AJUSTE SEGUNDO SEGUNDO
            if @tipo_ss_id2 >0 
            BEGIN
      SET @SeguroSocialEmpleado2  = (@TotalIngresosAfectosSS * @empleado_porcentaje2)/100  
      SET @SeguroSocialPatronal2 = (@TotalIngresosAfectosSS * @patrono_porcentaje2 )/100 
      SET @irtra2   = (@TotalIngresosAfectosSS * @irtra_porcentaje2 )/100  
      SET @intecap2  = (@TotalIngresosAfectosSS * @intecap_porcentaje2  )/100 
      
     
      if @montoMaximoSeguro2 >0
      begin
      if @montoMaximoSeguro2 < @SeguroSocialEmpleado2
      begin
      set @SeguroSocialEmpleado2=@montoMaximoSeguro2
      end
      end
--set      @SeguroSocialEmpleado2=13
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
      ,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
           VALUES (@planilla_resumen_id,'Seguro Social B','Seguro Social Empleado B',-1,'',
            '','-',@SeguroSocialEmpleado2 ,@SeguroSocialEmpleado2,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
            1,2, 0, 1, 0, 1 )
            
            END
            
END         
            
      
set @total_descuentos  = @descuentos_no_ss     +@SeguroSocialEmpleado+@SeguroSocialEmpleado2        
set @total_sueldo_liquido  = 
(@total_extras +@total_ingresos + @sueldo_base_recibido + @bonificacion_base_recibido+@MONTO_SEPTIMOS) -
@total_descuentos-@descuento_anticipo_quincena 

--TOTAL PAGO  SALARIO
--ISR 
SET @isr =0 
--set @total_sueldo_liquido  = 3434
-- ACTUALIZAMOS LOS CALCULOS



----------- CAMBIO ***********************
--set @total_sueldo_liquido= (
--select SUM([*Liquido a Recibir])  from dbo.Marzo15
-- where RTRIM(id) = @empleado_id
--)
--set @total_sueldo_liquido= ( ISNULL(@total_sueldo_liquido,0))
-------------******************************

set @dias_ausencias = @dias_ausencias 

declare @montovacaciones  numeric(9,2) =0
--if @Es_Anticipo =0
--begin
--set @diasvacaiones  =10
if (@diasvacaiones >0)
begin
set @montovacaciones  =  
(select total_sueldo_liquido     from pl.Planilla_Cabecera  c inner join pl.Planilla_Resumen  re
on c.id = re.planilla_cabecera_id  where MONTH(fecha_inicio) =MONTH(@fechaini ) and vacacion  =1
and empleado_id = @empleado_id )

 set @montovacaciones  = ISNULL(@montovacaciones,0)

 if (@montovacaciones > 0)
begin

 insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
cuenta_contable , centro_costo ,identificar , monto, debe, haber, activo , created_by, updated_by ,
created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
select  @planilla_resumen_id   as  planilla_resumen_id,
'Vacaciones'  as tipo, 'Valor Vacaciones   '   as descripcion ,
'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
'+' as identificar , @montovacaciones  as  monto, 
@montovacaciones  as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
1 as id_detalle, 0 as cabecera_id    


end


set @total_sueldo_liquido = @total_sueldo_liquido + @montovacaciones 
end

--end

--select @planilla_resumen_id as plresu,  @dias_laborados, @empleado_id as empleadoi, @salario  as salario,  @salarioReal  as salarioreal, @DiasLaborales as diasba


UPDATE   pl.Planilla_Resumen 
SET ingresos_ss =@ingresos_ss ,ingresos_no_ss =@ingresos_no_ss,
monto_vacaciones =@montovacaciones,
dias_vacaciones  = @diasvacaiones ,
ingresos_isr=@ingresos_isr,ingresos_no_isr=@ingresos_no_isr,
descuento_ss=@SeguroSocialEmpleado,descuentos_no_ss=@descuentos_no_ss,
descuentos_isr=@descuentos_isr,descuentos_no_isr=@descuentos_no_isr,descuento_anticipo_quincena=@descuento_anticipo_quincena,
cant_extras_simples=@cant_extras_simples,monto_extras_simples=@monto_extras_simples,
cant_extras_dobles=@cant_extras_dobles,monto_extras_dobles=@monto_extras_dobles,
cant_extras_extendidas=@cant_extras_extendidas,monto_extras_extendidas=@monto_extras_extendidas,
ingresos_afectos_prestaciones=@ingresos_afectos_prestaciones,ingresos_no_afectos_prestaciones=@ingresos_no_afectos_prestaciones,
sueldo_base_recibido=@sueldo_base_recibido,bonificacion_base_recibido=@bonificacion_base_recibido, 
isr=@isr,total_ingresos=@total_ingresos,total_descuentos=@total_descuentos,
total_extras=@total_extras,total_sueldo_liquido=@total_sueldo_liquido, 
septimos=@SEPTIMOS_OBTENIDOS , monto_septimos = @MONTO_SEPTIMOS,
dias_ausencias = @dias_ausencias ,
anticipo_quincena= @descuento_anticipo_quincena,
dias_suspendido = @dias_suspendidos ,
dias_laborados = @dias_laborados 
where id= @planilla_resumen_id 



--- PROVISIONES 

      SET @provision_bono14   = (@total_sueldo_liquido  * @provision_bono14 )/100  
      SET @provision_aguinaldo  = (@total_sueldo_liquido* @provision_aguinaldo  )/100 
      SET @provision_vacaciones   = (@total_sueldo_liquido * @provision_vacaciones )/100  
      SET @provision_indemizacion  = (@total_sueldo_liquido * @provision_indemizacion   )/100 
--    print 'Provisiones ---------------------------------'
      
EXEC Pl.ICtasProvisionesPlanilla  @planilla_resumen_id,   @planillacabecera,
        @provision_bono14, @provision_aguinaldo,@provision_vacaciones,@provision_indemizacion,
        @SeguroSocialEmpleado ,@SeguroSocialPatronal,@irtra,@intecap

END

