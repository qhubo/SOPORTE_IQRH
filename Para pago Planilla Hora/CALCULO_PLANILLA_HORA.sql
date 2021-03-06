USE [rh_skech]
GO
/****** Object:  StoredProcedure [pl].[CalculoPlanillaEmpleadoHora]    Script Date: 05/03/2019 11:45:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER  PROCEDURE  [pl].[CalculoPlanillaEmpleadoHora] (
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
--set @empleado_porcentaje=3

---*******   segundo porcentaje 



declare @horas_en_dia numeric(9,2)
set @horas_en_dia  = @horasdiarias / @diasbase 


print 'dias base ' + rtrim(@diasbase)
print 'horas diarias '+ rtrim(@horasdiarias)
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



--- VARIABLES PARA  CALCULO POR EMPLEADO
DECLARE @dias_ausencias numeric(9,2) =0
DECLARE @sueldo_base numeric(9,2) 
DECLARE @diascontrato numeric(9,2)
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
DECLARE @isr numeric(9,2)=0
DECLARE @planilla_resumen_id int 
DECLARE @MONTO_SEPTIMOS numeric(9,2) =0
DECLARE @SEPTIMOS_OBTENIDOS numeric(8,2)=0 
DECLARE @Idanticipocabecera  numeric(9,2) 
DECLARE @usaantiquince int
DECLARE @diaslaboradosCalend numeric(8,2) 
set @descuento_anticipo_quincena = 0  
declare @diasvacaiones numeric(9,2) =0
declare @ValidoDiariobase  bit
declare @ValidoDiarioSueldo  bit


------------SEPTIMOS OBTENIDOS  ------ LLENAR VARIABLE-------------
------------------------------
------------------------------------------------------------------

set @idcontrato = (select top 1  id  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id    and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  order by id desc  )
-- MODIFICAR MODIFICAR salario Base





-- bonificacion base
-- INSERTAR
SET @bonificacionbase = (select top 1  isnull(bono_base,0)  from rh.Empleado_Proyecto  where id = @idcontrato)
set @ValidoDiariobase  =  (select top 1  isnull(diariob,0)  from rh.Empleado_Proyecto  where id = @idcontrato)              
SET @sueldo_base  = (select top 1  isnull(salario ,0)  from rh.Empleado_Proyecto  where id = @idcontrato)
set @ValidoDiarioSueldo  =  (select top 1  isnull(diario,0)  from rh.Empleado_Proyecto  where id = @idcontrato)
set @dias_laborados =(select SUM(hora) from  pl.planilla_evento_hora h inner join pl.planilla_evento even on
h.planilla_evento_id  = even.id where fecha_dia >=@fechaini and fecha_dia <=@fechafin and empleado_id = @empleado_id)


set @dias_laborados = ISNULL(@dias_laborados,0)

IF @dias_laborados >0
BEGIN
--set @dias_laborados =1
----------********
if (@ValidoDiarioSueldo=0)
begin
SET @sueldo_base = (@sueldo_base/30) /8
end

--if (@ValidoDiarioSueldo  =0)
--begin
--SET @sueldo_base = (@sueldo_base/30) 
--end

if (@ValidoDiariobase =0)
begin
SET @bonificacionbase  = (@bonificacionbase/30) /8
end


set @bonificacion_base_recibido = @bonificacionbase * @dias_laborados
set @sueldo_base_recibido = @sueldo_base * @dias_laborados


  
--INSERTAMOS DATOS INICIALES 
INSERT INTO pl.Planilla_Resumen( dias_base,sueldo_base,bonificacion_base,salario_base, planilla_cabecera_id,
empleado_id,empleado_proyecto_id,dias_laborados,dias_ausencias, observaciones, activo,created_by,updated_by,created_at,updated_at )
VALUES (@diasbase ,  @sueldo_base , @bonificacionbase, @sueldo_base_recibido , @planillacabecera,
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



--TOTAL EXTRAS
set @total_extras  = @monto_extras_simples + @monto_extras_dobles + @monto_extras_extendidas  
-- set @baseCalculoINg =0
exec pl.ICIngreso_Detalle @planilla_resumen_id,@empleado_id, @tipo_planilla_id, @proyecto_id, @usuario ,  @fechafin , @Es_Anticipo, @diasbase,@dias_laborados,0


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

declare @ingresos_SEPTIMOS numeric(9,2) =0
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
set @baseCalculo = @sueldo_base_recibido + @ingresos_afectos_prestaciones + @bonificacion_base_recibido
--set @baseCalculo = @sueldo_base_recibido
-- CALCULO DE DESCUENTOS 
           
END   
exec pl.ICDescuento_Detalle  @planilla_resumen_id,@empleado_id, @tipo_planilla_id, @proyecto_id, @usuario , @fechafin, @Es_Anticipo, @baseCalculo, 0
print '*********************************************************'
print 'Calculo Descuentos Empleado ' + rtrim(@empleado_id)
print 'pl.ICDescuento_Detalle '  + rtrim(@planilla_resumen_id)+','+ rtrim(@empleado_id)+ ','+ rtrim(@tipo_planilla_id) +','+ rtrim(@proyecto_id) +','+ rtrim(@usuario)  +','+ rtrim(@fechafin) +','+ rtrim(@Es_Anticipo) +',' + rtrim(@sueldo_base)
print '*********************************************************'


-- DETALLE DE DESCUENTOS
select * into #temdes from pl.Planilla_Detalle  where tipo = 'Descuento'  and  planilla_resumen_id  = @planilla_resumen_id
set @descuento_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=1)
set @descuento_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=1)


set @descuentos_no_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=0)
set @descuentos_isr  = (select isnull(SUM(monto),0) from #temdes where afecta_isr=1)
set  @descuentos_no_isr  = (select isnull(SUM(monto),0) from #temdes where afecta_isr=0)
--set @descuentos_no_ss  = 0
drop table #temdes



        
      --- CALCULO DE SEGURO SOCIAL
DECLARE @TotalIngresosAfectosSS numeric(9,2)
DECLARE @SeguroSocialEmpleado  numeric(9,2) =0
DECLARE @SeguroSocialPatronal numeric(9,2)=0
DECLARE @irtra  numeric(9,2) =0
DECLARE @intecap numeric(9,2) =0





--set @calculoIgg=1
--set @usa_anticipo_seguro_social =1
------------------ CALCULA IGGS A RETIROS BAJAS
      SET @SeguroSocialEmpleado  = 0 
      SET @SeguroSocialPatronal =0
      SET @TotalIngresosAfectosSS  = @sueldo_base_recibido + @ingresos_ss
            SET @SeguroSocialEmpleado  = (@TotalIngresosAfectosSS * @empleado_porcentaje)/100  
                  SET @SeguroSocialPatronal = (@TotalIngresosAfectosSS * @patrono_porcentaje )/100 
      --SET @irtra   =0   
      --SET @intecap  =0 
      INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
      ,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
            columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
           VALUES (@planilla_resumen_id,'Seguro Social','Seguro Social Empleado',0,'',
            '','-',@SeguroSocialEmpleado ,@SeguroSocialEmpleado,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),1,2, 0, 1, 0, 1 )
            --*** AJUSTE SEGUNDO SEGUNDO           
      
            
      
set @total_descuentos  = @descuentos_no_ss     +@SeguroSocialEmpleado      
set @total_sueldo_liquido  = (@total_extras +@total_ingresos + @sueldo_base_recibido + @bonificacion_base_recibido+@MONTO_SEPTIMOS) -
@total_descuentos-@descuento_anticipo_quincena 


set @total_sueldo_liquido = @total_sueldo_liquido 

--select @planilla_resumen_id as plresu,  @dias_laborados, @empleado_id as empleadoi, @salario  as salario,  @salarioReal  as salarioreal, @DiasLaborales as diasba


UPDATE   pl.Planilla_Resumen 
SET ingresos_ss =@ingresos_ss ,ingresos_no_ss =@ingresos_no_ss,
monto_vacaciones =0,
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
dias_suspendido =0 ,
dias_laborados = @dias_laborados 
where id= @planilla_resumen_id 

END