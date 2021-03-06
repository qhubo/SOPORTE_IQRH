USE [grupoazur]
GO
/****** Object:  StoredProcedure [pl].[ICIngreso_Detalle]    Script Date: 07/12/2018 16:05:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE [rh_improlacsa_prod]
--GO
--/****** Object:  StoredProcedure [pl].[ICIngreso_Detalle]    Script Date: 06/21/2016 21:44:40 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

ALTER PROCEDURE [pl].[ICIngreso_Detalle]
(
 @planillaresumen  varchar(10),
 @idempleado int,
 @tipoplanilla int,
 @proyectoid int,
 @usuario varchar(32),
 @fecha varchar(10),
 @es_anticipo bit,
 @diasbase int,
 @dias_laborados int,
 @salario numeric(9,2)
)
as
--#PENDIENTE VALIDAR LA FECHA DE INICIO
begin

declare @fechar varchar(10) = @fecha
declare @dia int = SUBSTRING(@fechar,7,2) 
declare @afecto nvarchar(100) = 'Activo Planillas'
if (@dia =15)
begin
set @afecto  = 'Primer Quincena'
end
else
begin
set @afecto  = 'Segunda Quincena'
end


if @es_anticipo =0
begin
--- ACTIVA LOS PORCENTAJES PENDIENTES 
update  rh.Empleado_Ingreso set activo =1  where tipo_ingreso_id in (
select id from cat.Tipo_Ingreso  where porcentaje_anticipo > 0 and aplica_anticipo_quincenal=1)
and valor > 0 
and id in (
select cabecera_id from pl.Planilla_Detalle
d inner join pl.Planilla_Resumen r  on d.planilla_resumen_id  = r.id
where concepto_id 
 in (select id from cat.Tipo_Ingreso  where porcentaje_anticipo > 0 and aplica_anticipo_quincenal=1)
 and r.planilla_cabecera_id  in (
select top 1 id from pl.Planilla_Cabecera
where historico =0 and anticipo =1
  order by id desc ) and monto > 0)
  
end

	declare @centrocosto varchar(40)
    set @centrocosto  = ''
	create table  #tableresultado (tipoingreso integer, valor  numeric(9,2),empleado_id int, id_detalle int, cabecera_id int)

-- NORMALES
	insert into #tableresultado(tipoingreso,valor ,empleado_id,id_detalle, cabecera_id ) 
	select  t.tipo_ingreso_id,  
	--t.valor,
	
--	 case when porcentaje > 0 then ((@salario * porcentaje )/100) + valor else valor end valor, 
	 
	case  when  ti.comision  = 1 then (t.valor * @dias_laborados ) / @diasbase 
     when porcentaje > 0 then ((@salario * porcentaje )/100) + valor
	else t.valor end ,
	t.empleado_id,0,t.id from rh.Empleado_Ingreso t 
	inner join cat.Tipo_Ingreso  ti on t.tipo_ingreso_id =ti.id
	where 	t.siguiente_planilla =0 and t.tipo_planilla_id  = @tipoplanilla  and t.proyecto_id  = @proyectoid
	  and t.empleado_id = @idempleado and t.especial = 0 and t.activo  = 1  and t.fecha <= @fecha 
	  and (valor >0 or porcentaje >0)
	    and (isnull(afecto,'') ='' or afecto ='' or afecto ='Activo Planillas' or afecto =@afecto   )
	  
	  
	  
---EMPLEADO  ESPECIALES
	select  CAST (t.id as varchar(10))  as idingreso, IDENTITY(int,1,1) as id, t.tipo_ingreso_id 
	into #temporalingreso   from rh.Empleado_Ingreso t where  siguiente_planilla =0 and
    tipo_planilla_id  = @tipoplanilla  and proyecto_id  = @proyectoid 
     and empleado_id = @idempleado and especial = 1  and fecha <= @fecha  	  and valor >0
	and activo = 1
	declare @conte int
	declare @iding int
	declare @tipoingreso int 
    declare @cabecera_id int 
	set @conte =1
	while @conte <= (select MAX(id) from #temporalingreso)
	begin
		set @tipoingreso  = (select tipo_ingreso_id from #temporalingreso where id = @conte) 
		set @iding  = (select idingreso from #temporalingreso where id = @conte)
 		set @conte = @conte +1
 		insert into #tableresultado(tipoingreso,valor,empleado_id, id_detalle,cabecera_id ) 
		select top 1  @tipoingreso as tipo_ingreso_id, valor, @idempleado  as empleado_id, id, @iding  
		from rh.Empleado_Ingreso_Detalle  where siguiente_planilla =0 and empleado_ingreso_id = @iding order by id desc  
	end
	drop table #temporalingreso 
	
	if (@es_anticipo  = 0)
	begin
	INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
	,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
	columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle, cabecera_id, afecta_septimo     )
	select @planillaresumen, 'Ingreso',descripcion,tem.tipoingreso, tip.cuenta_contable,
	@centrocosto, '+', 
		case when isnull(porcentaje_anticipo,0)  = 0 	then tem.valor else
	(tem.valor  )  end val,
	0, 
		case when isnull(porcentaje_anticipo,0)  = 0 	then tem.valor else
	(tem.valor  * porcentaje_anticipo)  end val2,
	 1,@usuario, @usuario, 
	GETDATE(), GETDATE(),tip.agregar_columna,tip.orden, incluye_isr,  tip.afecta_ss,  afecta_prestaciones ,
    tem.id_detalle, tem.cabecera_id, isnull(aplica_septimo,0)  from #tableresultado tem inner join cat.Tipo_Ingreso  tip 
    on tem.tipoingreso  = tip.id
	end
	
	if (@es_anticipo  = 1)
	begin
	
	INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
	,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
	columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle, cabecera_id, afecta_septimo    )
	select @planillaresumen, 'Ingreso',descripcion,tem.tipoingreso, tip.cuenta_contable,
	@centrocosto, '+', 
	case when isnull(porcentaje_anticipo,0)  = 0 	then tem.valor else
	(tem.valor  * porcentaje_anticipo) /100 end val,0, 
		case when isnull(porcentaje_anticipo,0)  = 0 	then tem.valor else
	(tem.valor  * porcentaje_anticipo) /100 end val3,	
	 1,@usuario, @usuario, 
	GETDATE(), GETDATE(),tip.agregar_columna,tip.orden, incluye_isr, tip.afecta_ss,  afecta_prestaciones ,
    tem.id_detalle, cabecera_id, isnull(aplica_septimo,0) from #tableresultado tem inner join cat.Tipo_Ingreso  tip 
    on tem.tipoingreso  = tip.id      and aplica_anticipo_quincenal = 1 
      and (isnull(afecto,'') ='' or afecto ='' or afecto ='Activo Planillas' or afecto =@afecto   )
	end
	
	
	drop table #tableresultado
end
