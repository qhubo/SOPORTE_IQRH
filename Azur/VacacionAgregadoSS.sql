USE [grupoazur]
GO
/****** Object:  StoredProcedure [pl].[VacacionPlanilla]    Script Date: 09/07/2018 11:42:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [pl].[VacacionPlanilla] 
(
@idvacacion int 
)
as
-- declare @idvacacion int = 113
declare @proyecto int
declare @empleado_id int

set @proyecto  = (select proyecto_id   from pl.Empleado_Vacacion where id = @idvacacion )
set @empleado_id   = (select rh_empleado_id    from pl.Empleado_Vacacion where id = @idvacacion )
--declare @ano varchar(4)
--declare @inicioplanilla varchar(10)
--declare @finplanilla varchar(10)
--declare @mes int
declare @numero int
declare @empleadoProyectoid int
declare @montovacaciones numeric(9,2)
declare @montobase numeric(9,2)
declare @diavacaciones int
declare @sueldobase numeric(9,2)
declare @iniciaempleado date
declare @bonificacionbase numeric(9,2)

declare @tipoPlanilla  int = (select tipo_planilla_id  from pl.Empleado_Vacacion where id = @idvacacion )


declare @tipo_ss_id int 
set @tipo_ss_id = (select top 1  tipo_ss_id from rh.Empleado_Proyecto where tipo_planilla_id = @tipoPlanilla and proyecto_id = @proyecto
and empleado_id = @empleado_id order by id desc)

if @tipo_ss_id is null
begin
set @tipo_ss_id = (select tipo_ss_id from rh.Tipo_Planilla where id = @tipoPlanilla)
end

declare @empleado_porcentaje numeric(9,2)     
SET @empleado_porcentaje = (select empleado_porcentaje from cat.Tipo_ss where id = @tipo_ss_id )






set @iniciaempleado  = (select fecha_inicio     from pl.Empleado_Vacacion where id = @idvacacion )
set @montovacaciones   = (select monto    from pl.Empleado_Vacacion where id = @idvacacion )
set @diavacaciones   = (select dias   from pl.Empleado_Vacacion where id = @idvacacion )
set @empleadoProyectoid  = (select id from rh.Empleado_Proyecto  where empleado_id = @empleado_id
and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)

set @sueldobase = (select salario  from rh.Empleado_Proyecto  where empleado_id = @empleado_id
and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)

set @bonificacionbase  = (select bono_base   from rh.Empleado_Proyecto  where empleado_id = @empleado_id
and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)

declare @fechainicio  date =  (select fecha_inicio   from pl.Empleado_Vacacion where id = @idvacacion )
declare @frecuenciapago int 
set @frecuenciapago  = (select  frecuencia_pago_id  from rh.Tipo_Planilla  where  id = @tipoPlanilla )
declare @diasbase int
set @diasbase  = (select diasbase  from cat.FrecuenciaPago  where id = @frecuenciapago)
set @diasbase=30
declare @mesdescrip varchar(2)
declare @planilla_resumen_id int
declare @planilla_cabeceraid int 
declare @diavaca numeric(9,2)
declare @fechaount date
--select @iniciaempleado





exec pl.PeriodoVacacion @idvacacion, @iniciaempleado, @planilla_cabeceraid out
declare @inicioplanilla varchar(10) = (select CONVERT(varchar(10), fecha_inicio,102) from pl.Planilla_Cabecera where id = @planilla_cabeceraid)
declare @finplanilla varchar(10) = (select  CONVERT(varchar(10),fecha_fin,102)  from pl.Planilla_Cabecera where id = @planilla_cabeceraid)
set @inicioplanilla = REPLACE(@inicioplanilla, '.','')
set @finplanilla  = REPLACE(@finplanilla , '.','')
--delete from pl.Planilla_Detalle
--where planilla_resumen_id  in (
--select id from  pl.Planilla_Resumen  where empleado_id =@empleado_id  and planilla_cabecera_id = @planilla_cabeceraid 
--)
--delete from pl.Planilla_Resumen  where empleado_id =@empleado_id  and planilla_cabecera_id = @planilla_cabeceraid 
exec  pl.DiasVacaciones @inicioplanilla, @finplanilla,8,@empleado_id,@proyecto , @diavaca  out 
-----************-----------------select @inicioplanilla, @finplanilla , 8,@empleado_id , @proyecto , @diavaca 
--pl.DiasVacacionesFecha
exec [pl].[DiasVacacionesPlanilla] @inicioplanilla, @finplanilla,@idvacacion,@empleado_id,@proyecto , @fechaount  out
-- exec [pl].[DiasVacacionesFecha] @inicioplanilla, @finplanilla,8,@empleado_id,@proyecto , @fechaount  out
--- *****SE

declare @usanticipo_quincenal bit =(select usa_anticipo_quincenal from rh.Tipo_Planilla where  id =@tipoPlanilla )
declare @porcentaje_anticipo numeric(9,2) =(select  porcentaje_anticipo from rh.Tipo_Planilla where  id =@tipoPlanilla )
--select @diavaca as diavaca, @inicioplanilla  as inicio, @finplanilla as finplanilla
----- *****SE
--select @montovacaciones  as montovacacio
----- *****SE
--select @sueldobase , @diasbase , @diavaca 


exec  pl.Promedio12Vaca @empleado_id ,@proyecto, @sueldobase out
--select @montoPromedio as promedio


set @montovacaciones  = (@sueldobase / @diasbase) *@diavaca
set @montobase   = (@bonificacionbase / @diasbase) *@diavaca
set @porcentaje_anticipo =0 
if @porcentaje_anticipo  >0 
begin
--------if (DAY(CAST(@inicioplanilla as  date)) <15) 
--------	begin
--------	 set @montovacaciones = (@montovacaciones *@porcentaje_anticipo )/100
--------	end
--------	else 
	--------begin
	 set @montobase  = (@montobase  *(100-@porcentaje_anticipo) )/100
	 set @montovacaciones = (@montovacaciones *(100-@porcentaje_anticipo) )/100
	------end
end

 --- *****SE
--select @montovacaciones 

---***** VERIFICAMOS EXISTA
declare @existe int 
declare @diasSuma numeric(9,2)=0
declare @montoSuma numeric(9,2)=0
set @existe = (select COUNT(*) from pl.Planilla_Resumen  where planilla_cabecera_id = @planilla_cabeceraid 
and empleado_id = @empleado_id )

declare @montoIggs numeric(9,2)
   


if @existe =0
begin
---**** agrega igss
SET @montoIggs   = (@montovacaciones * @empleado_porcentaje)/100  
set @montoIggs  = ISNULL(@montoIggs,0)

insert into  pl.Planilla_Resumen 
(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
 empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
 created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido , total_descuentos, descuento_ss  )

select @diasbase as dias_base, 
@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
@sueldobase  as salario_base ,
@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
@diavaca  as dias_laborados , @montovacaciones + @montobase-@montoIggs as  total_sueldo_liquido ,
''  as  observaciones, 1 as activo ,
 '' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @montobase, @montoIggs, @montoIggs 
   
     
set @planilla_resumen_id  = (select MAX(id)from pl.Planilla_Resumen )
end
else 
begin
set @planilla_cabeceraid = (select planilla_cabecera_id from pl.Planilla_Resumen  where planilla_cabecera_id = @planilla_cabeceraid 
and empleado_id = @empleado_id)
set @diasSuma  = (select dias_laborados  from pl.Planilla_Resumen  where planilla_cabecera_id = @planilla_cabeceraid 
and empleado_id = @empleado_id)
set @montoSuma = (select sueldo_base_recibido  from pl.Planilla_Resumen  where planilla_cabecera_id = @planilla_cabeceraid 
and empleado_id = @empleado_id)
declare @bonoSuma numeric(9,2)
set @bonoSuma = (select bonificacion_base_recibido   from pl.Planilla_Resumen  where planilla_cabecera_id = @planilla_cabeceraid 


and empleado_id = @empleado_id)
set @planilla_resumen_id = (select id  from pl.Planilla_Resumen  where planilla_cabecera_id = @planilla_cabeceraid 
and empleado_id = @empleado_id)

---**** agrega igss
SET @montoIggs   = ((@montovacaciones + @montoSuma)* @empleado_porcentaje)/100  
set @montoIggs  = ISNULL(@montoIggs,0)




update pl.Planilla_Resumen set sueldo_base_recibido = @montovacaciones + @montoSuma,
bonificacion_base_recibido   = @montobase  +@bonoSuma ,
total_sueldo_liquido = @montovacaciones + @montoSuma +@bonoSuma +@montobase-@montoIggs  ,
 dias_laborados = @diasSuma +@diavaca ,
 total_descuentos = @montoIggs, descuento_ss=@montoIggs
 where id = @planilla_resumen_id
 
update pl.Planilla_Resumen 
 set  bonificacion_base_recibido =(bonificacion_base /30) *  dias_laborados 
 where id = @planilla_resumen_id
 

end



insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
cuenta_contable , centro_costo ,identificar , monto, debe, haber, activo , created_by, updated_by ,
created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
select @planilla_resumen_id  as  planilla_resumen_id,
'Vacaciones'  as tipo, 'Valor Vacaciones ' as descripcion ,
'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
'+' as identificar , @montovacaciones  as  monto, 
@montovacaciones  as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
1 as id_detalle, 0 as cabecera_id       


insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
cuenta_contable , centro_costo ,identificar , monto, debe, haber, activo , created_by, updated_by ,
created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
select @planilla_resumen_id  as  planilla_resumen_id,
'Vacaciones'  as tipo, 'Valor Vacaciones Bonificacion ' as descripcion ,
'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
'+' as identificar , @montobase  as  monto, 
@montobase    as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
1 as id_detalle, 0 as cabecera_id   


if (@montoIggs >0)
begin
insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
cuenta_contable , centro_costo ,identificar , monto, haber, debe, activo , created_by, updated_by ,
created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
select @planilla_resumen_id  as  planilla_resumen_id,
'Vacaciones'  as tipo, 'Valor Vacaciones SS' as descripcion ,
'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
'-' as identificar , @montoIggs   as  monto, 
@montoIggs     as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
1 as id_detalle, 0 as cabecera_id  
end




set @fechaount  = (select fecha_fin     from pl.Empleado_Vacacion where id = @idvacacion )
--select  'Segunda Planilla'
select @fechaount as fechaout, '>', @finplanilla as fechafin 
-------------***SEGUNDA PLANILLA
IF @fechaount > @finplanilla 
BEGIN

    declare @fechapro date 
    set @fechapro  = DATEADD(day,1, @finplanilla)
	exec pl.PeriodoVacacion @idvacacion, @fechapro , @planilla_cabeceraid out
	set @inicioplanilla = (select CONVERT(varchar(10), fecha_inicio,102) from pl.Planilla_Cabecera where id = @planilla_cabeceraid)
	set @finplanilla  = (select  CONVERT(varchar(10),fecha_fin,102)  from pl.Planilla_Cabecera where id = @planilla_cabeceraid)
	set @inicioplanilla = REPLACE(@inicioplanilla, '.','')
	set @finplanilla  = REPLACE(@finplanilla , '.','')
	delete from pl.Planilla_Detalle
	where planilla_resumen_id  in (
	select id from  pl.Planilla_Resumen  where empleado_id =@empleado_id  and planilla_cabecera_id = @planilla_cabeceraid 
	)
	delete from pl.Planilla_Resumen  where empleado_id =@empleado_id  and planilla_cabecera_id = @planilla_cabeceraid 
	
	
	exec  pl.DiasVacaciones @inicioplanilla, @finplanilla,8,@empleado_id,@proyecto , @diavaca  out 
	
	exec [pl].[DiasVacacionesPlanilla] @inicioplanilla, @finplanilla,@idvacacion,@empleado_id,@proyecto , @fechaount  out
	----exec [pl].[DiasVacacionesFecha] @inicioplanilla, @finplanilla,8,@empleado_id,@proyecto , @fechaount  out
	
	
	--- *****SE
	--select @fechaount  as fechaout
	set @usanticipo_quincenal  =(select usa_anticipo_quincenal from rh.Tipo_Planilla where  id =@tipoPlanilla )
	set @porcentaje_anticipo  =(select  porcentaje_anticipo from rh.Tipo_Planilla where  id =@tipoPlanilla )
	--select @diavaca as diavaca, @inicioplanilla  as inicio, @finplanilla as finplanilla
	----- *****SE
	--select @montovacaciones  as montovacacio
	----- *****SE
	--select @sueldobase , @diasbase , @diavaca 
	set @montovacaciones  = (@sueldobase / @diasbase) *@diavaca
	set @montobase   = (@bonificacionbase  / @diasbase) *@diavaca
	set @porcentaje_anticipo  =0
	if @porcentaje_anticipo  >0 
	begin
	--if (DAY(CAST(@inicioplanilla as  date)) <15) 
	--	begin
	--	 set @montovacaciones = (@montovacaciones *@porcentaje_anticipo )/100
	--	end
	--	else 
		--begin
		 set @montovacaciones = (@montovacaciones *(100-@porcentaje_anticipo) )/100
		 set @montobase  = (@montobase  *(100-@porcentaje_anticipo) )/100
		--end
	end
	
	---**** agrega igss
SET @montoIggs   = ((@montovacaciones + @montoSuma)* @empleado_porcentaje)/100  
set @montoIggs  = ISNULL(@montoIggs,0)


	
 --- *****SE
	--select @montovacaciones 
	insert into  pl.Planilla_Resumen 
		(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
		empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
		created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido, total_descuentos, descuento_ss   )
	select @diasbase as dias_base, 
	@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
	@sueldobase  as salario_base ,
	@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
	@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
	@diavaca  as dias_laborados , @montovacaciones + @montobase-@montoIggs   as  total_sueldo_liquido ,
	''  as  observaciones, 1 as activo ,
	'' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @bonificacionbase, @montoIggs, @montoIggs 
	
	      

	set @planilla_resumen_id  = (select MAX(id)from pl.Planilla_Resumen )
	insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
	cuenta_contable , centro_costo ,identificar , monto, debe, haber, activo , created_by, updated_by ,
	created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
	select @planilla_resumen_id  as  planilla_resumen_id,
	'Vacaciones complemento '  as tipo, 'Valor Complemento '  as descripcion ,
	'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
	'+' as identificar , @montovacaciones  as  monto, 
	@montovacaciones  as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
	GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
	1 as id_detalle, 0 as cabecera_id       

	insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
	cuenta_contable , centro_costo ,identificar , monto, debe, haber, activo , created_by, updated_by ,
	created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
	select @planilla_resumen_id  as  planilla_resumen_id,
	'Vacaciones complemento '  as tipo, 'Valor Complemento Bonificacion '  as descripcion ,
	'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
	'+' as identificar , @montobase    as  monto, 
	@montobase    as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
	GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
	1 as id_detalle, 0 as cabecera_id 
	
	
	if (@montoIggs >0)
begin
insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
cuenta_contable , centro_costo ,identificar , monto, haber, debe, activo , created_by, updated_by ,
created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
select @planilla_resumen_id  as  planilla_resumen_id,
'Vacaciones'  as tipo, 'Valor Vacaciones SS' as descripcion ,
'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
'-' as identificar , @montoIggs   as  monto, 
@montoIggs     as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
1 as id_detalle, 0 as cabecera_id  
end



	

END

--exec pl.VacacionCompleta @idvacacion