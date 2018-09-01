go
alter procedure [pl].[VistaResumenEmpleadoVacacionResumen]  --2609, 17, 13,2, '20160405'

(
@empleadoid int,
@proyectoid int,
@planillaid int ,
@opcion int ,
@fechar varchar(10) =null
)
as
declare @fecha date 
declare @bloquea bit
declare @periodo int 
create table #temporal (Periodo int, Derecho numeric(8,2), Pagado numeric(9,2), Nuevo bit)
declare @existe int
declare @nuevo bit 
declare @fin  date
set @fin = (select top 1  fecha_fin from pl.Planilla_Cabecera  
where anticipo =0  and tipo_planilla_id  =@planillaid 
and proyecto_id  = @proyectoid  order by fecha_fin desc )
if (rtrim(@fechar) <> '')
begin
set @fin = @fechar
end
--set @fin ='20160405'

if @opcion =3
begin

delete from pl.Empleado_Vacacion_Resumen  where empleado_id  = @empleadoid  and
proyecto_id = @proyectoid  and tipo_planilla_id = @planillaid
end





--declare @fecha date ='20160405' 
set @fecha = (select top 1 fecha_alta from rh.Empleado_Proyecto  where proyecto_id  =@proyectoid
and tipo_planilla_id  = @planillaid and empleado_id = @empleadoid
and activo= 1)
declare @diferencia numeric(9,2)
set @diferencia = ( select DATEDIFF(day,@fecha, @fin))+1

----*****select @diferencia as totaldias
      set @bloquea  =0
--declare @fecha date = '20130101'
--declare @fin date = '20130915'
      declare @anoInicial int = year(@fecha)
      set @periodo  =   year(@fecha)
      declare @diasperiodo  numeric(8,2)
      declare @diasEmpleadoPeriodo numeric(8,2)
      set @diasperiodo = (select   top  1 dias_periodo_vacaciones from  cat.Proyecto ) -- 360
      set @diasperiodo =365
      set @diasEmpleadoPeriodo =  (select top 1   dias_vacaciones  from rh.Empleado)  -- 15
      declare @resul numeric(9,2)
      set  @resul =(select @diferencia/@diasperiodo)
      --****select @resul as difrerencias
      declare @variable varchar(10) 
      --set @variable = CAST(@resul as varchar(10))
      --select @variable as variable
      declare @PeriodosEnteros int
      --set @PeriodosEnteros =cast((SUBSTRING(@variable,-4,6)) as int)
      set @PeriodosEnteros =cast(@resul as int)
      --select cast(15.39 as int)
      
      ---****select @PeriodosEnteros as perdiodoenter
--    exec pl.VistaResumenEmpleadoVacacionResumen 1709, 17,13,1
--select @variable, @PeriodosEnteros
            declare @resta  int
            set @resta  = @PeriodosEnteros * @diasperiodo
--select @diferencia as diferen, @resta as resta, @diferencia-@resta as resul
            declare @diaspendientes numeric(9,2)
            set @diaspendientes = @diferencia-@resta
            declare @diasDerecho numeric(9,2)
            set @diasDerecho  = (select (@diaspendientes  * @diasEmpleadoPeriodo ) / @diasperiodo)
            
      --    select @diaspendientes, @diasEmpleadoPeriodo, @diasperiodo 
            declare @diaspagado numeric(8,2)
--select @PeriodosEnteros as periodos, @diaspendientes as dias, @diasDerecho as derecho
      declare @conte int =0
      declare @suma int =0
      while(@conte < @PeriodosEnteros) 
      begin
      --select isnull(sum(Pagado),0) from pl.Empleado_Vacacion_Resumen  
      --     where  Periodo  =2011 and empleado_id =4  and
      --      proyecto_id =3 and tipo_planilla_id  =2
            
          set @diaspagado  = (select isnull(sum(Pagado),0) from pl.Empleado_Vacacion_Resumen  
           where  Periodo  =@anoInicial  + @conte and empleado_id =@empleadoid  and
            proyecto_id =@proyectoid  and tipo_planilla_id  =@planillaid 
            -- and Nuevo  = 0 
             )
             set @nuevo  =1
            if @diaspagado  > 0
            begin 
                   set @nuevo  =0
            end
            insert into #temporal
            select @anoInicial  + @conte , @diasEmpleadoPeriodo, @diaspagado ,@nuevo 
            set @conte = @conte +1
      end
      set @diaspagado  = (select isnull(sum(Pagado),0) from pl.Empleado_Vacacion_Resumen  
           where  Periodo  =@anoInicial  + @conte and empleado_id =@empleadoid  and
          proyecto_id =@proyectoid  and tipo_planilla_id  =@planillaid 
          -- and Nuevo  = 0 
           )
      set @nuevo  =1
      if @diaspagado  > 0
      begin 
             set @nuevo  =0
      end

insert into #temporal     
select @anoInicial+ @conte, @diasDerecho,@diaspagado ,@nuevo 


--select * from #temporal



set @existe = (select COUNT(*) from pl.Empleado_Vacacion_Resumen
where empleado_id = @empleadoid  and proyecto_id = @proyectoid  and tipo_planilla_id  = @planillaid)


if @existe > 0
begin
set @bloquea  =1
set @periodo  = (select max(periodo) from #temporal)

--set @periodo =2020
end


declare @existependi  int = (
select COUNT(*) from pl.Empleado_Vacacion_Resumen
where empleado_id = @empleadoid  and proyecto_id = @proyectoid  and tipo_planilla_id  = @planillaid
  and Pagado < Derecho )
  
if (@existependi  >0)
begin
set @periodo = (select MIN(periodo) from pl.Empleado_Vacacion_Resumen
where empleado_id = @empleadoid  and proyecto_id = @proyectoid  and tipo_planilla_id  = @planillaid
  and Pagado < Derecho )
end




if (@opcion=1)
begin
select * from #temporal
end


      
declare @fechainici varchar(10)
declare @fechafin varchar(10)
declare @derecho numeric(9,2)
declare @pagado numeric(9,2)

set @fechainici = ( CONVERT(varchar(10),@fecha,103))
set @fechafin  = ( CONVERT(varchar(10),@fin,103))
set @derecho = (select SUM(Derecho) from #temporal)
set @pagado  = (select SUM(Pagado) from #temporal)


if (@opcion = 2)
begin
declare @historico int = (   select COUNT(*) from pl.Empleado_Vacacion_Resumen where  empleado_id = @empleadoid)
      
      if @historico >0
      begin
      

select @fechainici as Inicio, @fechafin  as Fin, @diferencia  as Dias,
@derecho  as Derecho, @pagado as Pagados,
@bloquea as bloquea, @periodo as periodo
end
else
begin

select @fechainici as Inicio, @fechafin  as Fin, @diferencia  as Dias,
CAST( (@diferencia *15) / @diasperiodo  as numeric(9,2)) as Derecho, 
 0 as Pagados,
@bloquea as bloquea, @periodo as periodo

end

delete from   [dbo].[Vacacion_Temporal] where empleado_id = @empleadoid 
and proyecto_id = @proyectoid  and tipo_planilla_id =@planillaid

--select COUNT(*) from pl.Empleado_Vacacion_Resumen where  empleado_id = @empleadoid


insert into [dbo].[Vacacion_Temporal](empleado_id, proyecto_id, tipo_planilla_id, periodo,pagado, derecho, nuevo)

select @empleadoid, @proyectoid, @planillaid, periodo, pagado, derecho, nuevo      from #temporal
      
end



--select * from [dbo].[Vacacion_Temporal]
if @opcion =3
begin

delete from pl.Empleado_Vacacion_Resumen  where empleado_id  = @empleadoid  and
proyecto_id = @proyectoid  and tipo_planilla_id = @planillaid 
insert into pl.Empleado_Vacacion_Resumen  
 (empleado_id,proyecto_id, tipo_planilla_id, Periodo, Derecho, Pagado, Nuevo,
created_at, created_by   )
  select @empleadoid, @proyectoid, @planillaid, Periodo,
Derecho, Pagado, Nuevo ,GETDATE (),'' from #temporal
end

 
 
 
 drop table #temporal





GO

go
alter  procedure [pl].[VistaPlanillasVacaciones]
(
@proyectoid int,
@planillaid int,
@empleado int,
@opcion int

)
as
declare @metodo varchar(32) 
declare @calculo varchar(32)
set @metodo= 'Percibido (Pagado Real)'
set @metodo= 'Devengado (Contratacion)'
set @calculo ='Ultimo Sueldo'
set @calculo ='Promedio Seis Meses'
set @calculo ='Promedio Doce Meses'
set @calculo  = (select rtrim(calculo_vacaciones)   from cat.Proyecto where id = @proyectoid ) 
set @metodo  =(select  rtrim(metodo_vacaciones)   from cat.Proyecto where id = @proyectoid )
create table #tempo (finDate date, Inicio varchar(10), Fin varchar(10), Sueldo numeric(8,3),
 Bonificacion numeric(9,2), Extraordinario numeric(9,2), Ingresos numeric(9,2),
 Septimos numeric(9,2) ,Dias numeric(9,2), Afecta  bit) 
if (RTRIM(@metodo)) = 'Devengado (Contratacion)'
begin
insert into #tempo
select fecha_fin,
convert(varchar(10), fecha_inicio,103) as Inicio,
 convert(varchar(10), fecha_fin,103) as Fin, 
sueldo_base as Sueldo, 
 bonificacion_base as 'Bonificacion Decreto',
total_extras as Extraordinario, ingresos_afectos_prestaciones as 'Ingresos', 
monto_septimos,dias_base as Dias , 0   from pl.Planilla_Resumen 
res inner join pl.Planilla_Cabecera  ca  on res.planilla_cabecera_id  = ca.id
 where empleado_id  =@empleado and ca.anticipo  =0
 and tipo_planilla_id  = @planillaid  and proyecto_id = @proyectoid 
 and ca.activo =0
 order by fecha_fin  desc

end

if (RTRIM(@metodo)) ='Percibido (Pagado Real)'
begin
insert into #tempo
select fecha_fin, convert(varchar(10), fecha_inicio,103) as Inicio,
  convert(varchar(10), fecha_fin,103) as Fin,  sueldo_base_recibido as Sueldo, 
  bonificacion_base_recibido as 'Bonificacion Decreto',
  total_extras      as Extraordinario, ingresos_afectos_prestaciones as 'Ingresos',
 monto_septimos ,    dias_laborados as Dias,0 as Afecta from pl.Planilla_Resumen 
res inner join pl.Planilla_Cabecera  ca  on res.planilla_cabecera_id  = ca.id
 where empleado_id  =@empleado and ca.anticipo  =0
 and tipo_planilla_id  = @planillaid  and proyecto_id = @proyectoid 
 and ca.activo =0
 order by fecha_fin  desc
end

declare @ultima date
set @ultima  = (select top 1 finDate from #tempo order by finDate desc )
update #tempo set afecta =1 where finDate >= @ultima

if @calculo  = 'Promedio Seis Meses'
begin
set @ultima =  DATEADD(month,-5,@ultima)
update #tempo set afecta =1 where finDate > @ultima
end


if @calculo  = 'Promedio Doce Meses'
begin
set @ultima =  DATEADD(day,-365,@ultima)
update #tempo set afecta =1 where finDate > @ultima
end
--select @calculo, @metodo 
--select id, descripcion, metodo_vacaciones, calculo_vacaciones  from cat.Proyecto 
declare @totalsueldo numeric(9,2) = (select SUM(Sueldo) from #tempo where Afecta =1)
declare @totalbono numeric(9,2) = (select SUM(Bonificacion) from #tempo where Afecta =1) 
declare @extraordin numeric(9,2) = (select SUM(Extraordinario) from #tempo where Afecta =1)
declare @ingresos numeric(9,2) = (select SUM(Ingresos) from #tempo where Afecta =1)
declare @septimos numeric(9,2) = (select SUM(Septimos) from #tempo where Afecta =1)
declare @dias  numeric(9,2) = (select SUM(Dias) from #tempo where Afecta =1)
declare @TOTAL numeric(9,2) = @septimos + @totalsueldo
declare @usaingreso  bit =(select prov_vaca_ingresos  from rh.Tipo_Planilla  where id = @planillaid)
declare @usavacaboni bit=(select prov_vaca_boni  from rh.Tipo_Planilla  where id = @planillaid)
declare @usaextras bit =(select prov_vaca_extras from rh.Tipo_Planilla  where id = @planillaid)

if @usaingreso =1
begin
set @TOTAL = @TOTAL + @ingresos 
end
if @usaextras  =1
begin
set @TOTAL = @TOTAL + @extraordin 
end

if @usavacaboni =1
begin
set @TOTAL = @TOTAL + @totalbono
end
if (@opcion=1)
begin
select   Inicio,Fin, Sueldo, Bonificacion, Extraordinario, Ingresos,
 Septimos,Dias, Afecta, @empleado as rh_empleado_id from #tempo
 end
if (@opcion=2)
begin
declare @sueldodia numeric(9,2)= (select  (salario+ bono_base) /30
 from rh.Empleado_Proyecto where empleado_id = @empleado and activo =1)

set @sueldodia = ISNULL(@sueldodia,0)
select @metodo as Metodo, @calculo  as Calculo,
@totalsueldo  as Sueldo,
@totalbono  as Bonificacion,
 @extraordin  as ExtraOrdinario ,
 @ingresos  as Ingresos,
 @septimos  as Septimos,
 @TOTAL as Total,@dias as Dias,
 @sueldodia  as ValorDiario
 end 
 drop table #tempo

GO


alter Procedure [pl].[VacacionPlanilla] 
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

if @existe =0
begin
insert into  pl.Planilla_Resumen 
(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
 empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
 created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido   )

select @diasbase as dias_base, 
@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
@sueldobase  as salario_base ,
@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
@diavaca  as dias_laborados , @montovacaciones + @montobase as  total_sueldo_liquido ,
''  as  observaciones, 1 as activo ,
 '' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @montobase 
   
     
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


update pl.Planilla_Resumen set sueldo_base_recibido = @montovacaciones + @montoSuma,
bonificacion_base_recibido   = @montobase  +@bonoSuma ,
total_sueldo_liquido = @montovacaciones + @montoSuma +@bonoSuma +@montobase  ,
 dias_laborados = @diasSuma +@diavaca 
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
 --- *****SE
	--select @montovacaciones 
	insert into  pl.Planilla_Resumen 
		(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
		empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
		created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido   )
	select @diasbase as dias_base, 
	@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
	@sueldobase  as salario_base ,
	@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
	@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
	@diavaca  as dias_laborados , @montovacaciones + @montobase  as  total_sueldo_liquido ,
	''  as  observaciones, 1 as activo ,
	'' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @bonificacionbase 
	
	      

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
	
	

END

exec pl.VacacionCompleta @idvacacion
GO
go
alter Procedure [pl].[VacacionPlanilatest] 
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

if @existe =0
begin
--insert into  pl.Planilla_Resumen 
--(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
-- empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
-- created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido   )

select @diasbase as dias_base, 
@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
@sueldobase  as salario_base ,
@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
@diavaca  as dias_laborados , @montovacaciones + @montobase as  total_sueldo_liquido ,
''  as  observaciones, 1 as activo ,
 '' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @montobase 
   
     
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


--update pl.Planilla_Resumen set sueldo_base_recibido = @montovacaciones + @montoSuma,
--bonificacion_base  = @montobase  +@bonoSuma ,
--total_sueldo_liquido = @montovacaciones + @montoSuma +@bonoSuma +@montobase  ,
-- dias_laborados = @diasSuma +@diavaca 
-- where id = @planilla_resumen_id


end



--insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
--cuenta_contable , centro_costo ,identificar , monto, debe, haber, activo , created_by, updated_by ,
--created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
select @planilla_resumen_id  as  planilla_resumen_id,
'Vacaciones'  as tipo, 'Valor Vacaciones ' as descripcion ,
'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
'+' as identificar , @montovacaciones  as  monto, 
@montovacaciones  as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,
1 as id_detalle, 0 as cabecera_id       


--insert into pl.Planilla_Detalle  (planilla_resumen_id, tipo, descripcion , concepto_id , 
--cuenta_contable , centro_costo ,identificar , monto, debe, haber, activo , created_by, updated_by ,
--created_at , updated_at , columna_activo , orden, id_detalle  , cabecera_id )
select @planilla_resumen_id  as  planilla_resumen_id,
'Vacaciones'  as tipo, 'Valor Vacaciones Bonificacion ' as descripcion ,
'-1' as concepto_id , '' as cuenta_contable ,'' as centro_costo ,
'+' as identificar , @montobase  as  monto, 
@montobase    as debe,0 as haber, 1 as activo ,'' as  created_by,'' as updated_by ,
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,



1 as id_detalle, 0 as cabecera_id   

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
	set @porcentaje_anticipo  =0
	select @diavaca
	--select @sueldobase , @diasbase , @diavaca 
	set @montovacaciones  = (@sueldobase / @diasbase) *@diavaca
	set @montobase   = (@bonificacionbase  / @diasbase) *@diavaca
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
 --- *****SE
	--select @montovacaciones 
	insert into  pl.Planilla_Resumen 
		(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
		empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
		created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido   )
	select @diasbase as dias_base, 
	@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
	@sueldobase  as salario_base ,
	@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
	@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
	@diavaca  as dias_laborados , @montovacaciones + @montobase  as  total_sueldo_liquido ,
	''  as  observaciones, 1 as activo ,
	'' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @bonificacionbase 
	
	      

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
	
	

END

GO

go
alter procedure [pl].[VacacionCompleta]
(
@idvacacion  int
)
AS
BEGIN

declare @diasuma int =16
declare @diasbase int =30
--declare @idvacacion  int
--set @idvacacion =14



declare @fechaount date
declare @diavaca  int
declare @proyecto int
declare @empleado_id int
declare @periodo int
declare @pagado int
declare @iniciaempleado date
declare @fechafinaliza date 
declare @diapaga int
declare @sueldobase numeric (9,2)
declare @bonificacionbase numeric(9,2)
declare @tipoPlanilla int
declare @montovacaciones numeric(9,2)
declare @montobase numeric(9,2)
declare @empleadoProyectoid  int 
declare @planilla_resumen_id int

set @proyecto  = (select proyecto_id   from pl.Empleado_Vacacion where id = @idvacacion )
set @empleado_id   = (select rh_empleado_id    from pl.Empleado_Vacacion where id = @idvacacion )
set @periodo    = (select periodo     from pl.Empleado_Vacacion where id = @idvacacion )
set @tipoPlanilla  = (select tipo_planilla_id  from pl.Empleado_Vacacion  where id = @idvacacion)


set @pagado =(select Pagado  from pl.Empleado_Vacacion_Resumen  where empleado_id = @empleado_id 
and Nuevo =0 and Periodo = @periodo )


select @pagado 
IF @pagado = 15
BEGIN

set @fechafinaliza   = (select DATEADD(day, @diasuma,fecha_inicio)       from pl.Empleado_Vacacion where id = @idvacacion )
set @sueldobase = (select salario  from rh.Empleado_Proyecto  where empleado_id = @empleado_id
and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)

set @bonificacionbase  = (select bono_base   from rh.Empleado_Proyecto  where empleado_id = @empleado_id
and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)

set @empleadoProyectoid  = (select id  from rh.Empleado_Proyecto  where empleado_id = @empleado_id
and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)






set @iniciaempleado  = (select fecha_inicio     from pl.Empleado_Vacacion where id = @idvacacion )
declare @planilla_cabeceraid int 
exec pl.PeriodoVacacionCompleta @idvacacion, @iniciaempleado, @planilla_cabeceraid out
declare @inicioplanilla varchar(10) = (select CONVERT(varchar(10), fecha_inicio,102) from pl.Planilla_Cabecera where id = @planilla_cabeceraid)
declare @finplanilla varchar(10) = (select  CONVERT(varchar(10),fecha_fin,102)  from pl.Planilla_Cabecera where id = @planilla_cabeceraid)
set @inicioplanilla = REPLACE(@inicioplanilla, '.','')
set @finplanilla  = REPLACE(@finplanilla , '.','')
exec [pl].[DiasVacacionesPlanillaCompleta] @inicioplanilla, @finplanilla,@idvacacion,@empleado_id,@proyecto , @fechaount  out
set @diapaga =(select DATEDIFF(DAY,@iniciaempleado, @fechaount  )+1)


--- primer planilla

set @montovacaciones  = (@sueldobase / @diasbase) *@diapaga
set @montobase   = (@bonificacionbase / @diasbase) *@diapaga
--select @iniciaempleado  as inicio, @fechaount  as finaliza, 
--@planilla_cabeceraid  as planillacabeceraid, @diapaga as diapaga,
--@montovacaciones as montovacaciones, @montobase  as montobase
DECLARE @EXISTE INT 

------*********************-----------INGRESO
SET @EXISTE  = (select COUNT(*) from pl.Planilla_Resumen where empleado_proyecto_id = @empleadoProyectoid and planilla_cabecera_id  = @planilla_cabeceraid and empleado_id = @empleado_id )
SET @planilla_resumen_id   = (select id from pl.Planilla_Resumen where empleado_proyecto_id = @empleadoProyectoid and planilla_cabecera_id  = @planilla_cabeceraid and empleado_id = @empleado_id )
if @EXISTE =0
begin
	insert into  pl.Planilla_Resumen 
		(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
		empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
		created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido   )
	select @diasbase as dias_base, 
	@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
	@sueldobase  as salario_base ,
	@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
	@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
	@diapaga  as dias_laborados , @montovacaciones + @montobase  as  total_sueldo_liquido ,
	''  as  observaciones, 1 as activo ,
	'' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @montobase  
	set @planilla_resumen_id = (select MAX(id) from pl.Planilla_Resumen)
end


set @EXISTE  = (select COUNT(*) from pl.Planilla_Detalle  where planilla_resumen_id = @planilla_resumen_id and tipo = 'Vacaciones')
if @EXISTE =0
BEGIN

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
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,1 as id_detalle, 0 as cabecera_id 
END


----------******************************------------------------



if @fechafinaliza > @fechaount
begin
-- segunda
set @iniciaempleado = DATEADD(DAY,1, @fechaount)


exec pl.PeriodoVacacionCompleta @idvacacion, @iniciaempleado, @planilla_cabeceraid out


set @diapaga =( select DATEDIFF(DAY,@iniciaempleado, @fechafinaliza  )+1)
set @montovacaciones  = (@sueldobase / @diasbase) *@diapaga
set @montobase   = (@bonificacionbase / @diasbase) *@diapaga
---select @planilla_cabeceraid 
--select  @iniciaempleado  as inicia , @fechafinaliza  as finaliza, @planilla_cabeceraid as planillacabeceraId,
--@diapaga as diaspaga,@montovacaciones as montovacaciones, @montobase  as montobase

------*********************-----------INGRESO----------------------------------

SET @EXISTE  = (select COUNT(*) from pl.Planilla_Resumen where empleado_proyecto_id = @empleadoProyectoid and planilla_cabecera_id  = @planilla_cabeceraid and empleado_id = @empleado_id )
SET @planilla_resumen_id   = (select id from pl.Planilla_Resumen where empleado_proyecto_id = @empleadoProyectoid and planilla_cabecera_id  = @planilla_cabeceraid and empleado_id = @empleado_id )
if @EXISTE =0
begin
	insert into  pl.Planilla_Resumen 
		(dias_base, sueldo_base, bonificacion_base , salario_base , planilla_cabecera_id ,empleado_id ,
		empleado_proyecto_id, sueldo_base_recibido, dias_laborados , total_sueldo_liquido , observaciones, activo ,
		created_by, updated_by, created_at, updated_at, dias_suspendido, bonificacion_base_recibido   )
	select @diasbase as dias_base, 
	@sueldobase  as  sueldo_base, @bonificacionbase  as bonificacion_base , 
	@sueldobase  as salario_base ,
	@planilla_cabeceraid  as planilla_cabecera_id , @empleado_id as empleado_id ,
	@empleadoProyectoid  as empleado_proyecto_id, @montovacaciones  as sueldo_base_recibido, 
	@diapaga  as dias_laborados , @montovacaciones + @montobase  as  total_sueldo_liquido ,
	''  as  observaciones, 1 as activo ,
	'' as created_by, '' as updated_by, GETDATE() as  created_at,GETDATE() as  updated_at,0 , @montobase  
	set @planilla_resumen_id = (select MAX(id) from pl.Planilla_Resumen)
end


set @EXISTE  = (select COUNT(*) from pl.Planilla_Detalle  where planilla_resumen_id = @planilla_resumen_id and tipo = 'Vacaciones')
if @EXISTE =0
BEGIN

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
GETDATE() as created_at ,GETDATE() as  updated_at ,1 as columna_activo ,1 as orden,1 as id_detalle, 0 as cabecera_id 
END





----------******************************------------------------
end


END


END

GO

go
alter procedure  [pl].[ReporteEmpleadoVacacion]
(
@id int,
@opcion varchar(20)
)
as

declare @proyectoid int
declare @planillaid int
declare @empleaoid int

select  rh.nombre_empleado(rh_empleado_id) as nombre_empleado,
CONVERT(varchar(10), fecha_inicio,103) as FechaInicio,
CONVERT(varchar(10), fecha_fin,103) as FechaFin,
Dias, Monto, Pagada, Gozada, Estado,  Diaspaga , v.metodo_vacaciones,
v.Calculo_vacaciones, Periodo, pl.descripcion as Planilla, 
pro.descripcion  as Proyecto ,  case  when em.dpi  <> '' then dpi else pasaporte  end 
Identificacion, rh.codigo_empleado(rh_empleado_id, v.proyecto_id, v.tipo_planilla_id) as Codigo,
depar.descripcion  as Departamento, inicia_medio_dia, fin_medio_dia ,
salario,  CONVERT(varchar(10), fecha_alta, 103) as fecha_ingreso ,
rh_empleado_id, v.proyecto_id , v.tipo_planilla_id 
, day(fecha_inicio)as inicio_dia
, month(fecha_inicio)as inicio_mes
, YEAR(fecha_inicio)as inicio_ano
, day(fecha_fin)as fin_dia
, month(fecha_fin)as fin_mes
, YEAR(fecha_fin)as fin_ano
  into #tempodatos  from pl.Empleado_Vacacion v inner join cat.Proyecto pro  on pro.id = proyecto_id  
inner join rh.Tipo_Planilla pl on pl.id  = v.tipo_planilla_id 
inner join rh.Empleado em on em.id = rh_empleado_id
inner join rh.Empleado_Proyecto  emp on emp.tipo_planilla_id  =  v.tipo_planilla_id  
and emp.proyecto_id = v.proyecto_id and emp.empleado_id = rh_empleado_id 
left join cat.Empresa_Departamento  depar on depar.id = empresa_departamento_id 
where v.id =@id 

if @opcion = 'detalle'
begin
select  * from  #tempodatos
end


set @proyectoid = (select proyecto_id from #tempodatos)
set @planillaid = (select  tipo_planilla_id  from #tempodatos)
set  @empleaoid = (select rh_empleado_id from #tempodatos)
drop table #tempodatos 




if @opcion = 'resumen'
begin
exec pl.VistaPlanillasVacaciones  @proyectoid,@planillaid ,@empleaoid,1
end
--exec pl.VistaPlanillasVacaciones @proyectoid, @planillaid, @empleaoid




--select top 1  id from pl.Empleado_Vacacion where rh_empleado_id  = 72 and proyecto_id =17 and tipo_planilla_id =11

GO

alter  procedure [pl].[RechazaVacacion]
(
@id int,
@usuario varchar(40)
)
as
begin

delete from pl.Empleado_Vacacion_Gozada  where empleado_vacacion_id  = @id
delete from pl.Empleado_Vacacion_Pagada  where empleado_vacacion_id  = @id
delete from pl.Empleado_Vacacion_Gozada_Periodo   where empleado_vacacion_id  = @id
delete from pl.Empleado_Vacacion_Pagada_Periodo  where empleado_vacacion_id  = @id

update  pl.Empleado_Vacacion set estado  = 'Rechazado',
updated_at  = GETDATE(), updated_by  = @usuario 
where id =@id  
end

GO
go
alter procedure [pl].[RechazaCalculoVacacion]
(
@id int

)
as
declare @proyectoid int  = (select proyecto_id  from Empleado_Vacacion  where id = @id)
declare @empleadoid int  = (select rh_empleado_id  from Empleado_Vacacion  where id = @id)
declare @planillaid int  = (select tipo_planilla_id   from Empleado_Vacacion  where id = @id)


--declare @idpendiente int 
---- busca id
--set @idpendiente  = (select id   from pl.empleado_vacacion where estado  = 'Pendiente'
--and rh_empleado_id = @empleadoid  and proyecto_id =@proyectoid  and tipo_planilla_id  =@planillaid )
--set @idpendiente  = ISNULL(@idpendiente,0)
-- elimiina detalles
delete from pl.Empleado_Vacacion_Gozada  where empleado_vacacion_id  = @id 
delete from pl.Empleado_Vacacion_Pagada  where empleado_vacacion_id  = @id 
delete from pl.Empleado_Vacacion_Gozada_Periodo   where empleado_vacacion_id  = @id 
delete from pl.Empleado_Vacacion_Pagada_Periodo  where empleado_vacacion_id  = @id 

-- elimina peridos nuevos
delete from pl.Empleado_Vacacion_Resumen  where empleado_id = @empleadoid
and proyecto_id =@proyectoid  and tipo_planilla_id  =@planillaid  and Nuevo  = 1


-- si existe el id 
if @id  > 0
begin
-- busca dias y el periodo para retora
declare @dias  int = (select dias  from pl.Empleado_Vacacion where id = @id )
declare @periodo int = (select  periodo  from pl.Empleado_Vacacion where id = @id ) 

declare @pagados numeric(9,2) =(select   Pagado   from pl.Empleado_Vacacion_Resumen  
								where empleado_id = @empleadoid and proyecto_id =@proyectoid 
								 and tipo_planilla_id  =@planillaid  and Periodo = @periodo)
set @pagados  = ISNULL(@pagados,0)
set @dias = ISNULL(@dias,0)

declare @regresa numeric(9,2)
set @regresa   = @pagados  - @dias 
-- actualiza el regreso
 update  pl.Empleado_Vacacion_Resumen   set Pagado  = @regresa 
		where empleado_id = @empleadoid and proyecto_id =@proyectoid 
	 and tipo_planilla_id  =@planillaid  and Periodo = @periodo


end
-- elimina tabla final

update  pl.Empleado_Vacacion  set estado ='Rechazado'  where id = @id

GO

alter procedure [pl].[Ploxima_Planilla_Vacaciones_Fecha]
(
@idproyecto int,
@fecha_inicial_vacaciones date
)
as
begin

declare @diasbases int
declare @inicial varchar(10)
declare @final varchar(10)
declare @id int
declare @anticipo bit
declare @UlInicial varchar(10)
declare @UIFinal varchar(10)

--declare @idproyecto int
--set @idproyecto  =2 



set @id = 0
set @diasbases = (select   f.diasbase   from cat.Proyecto 
		pr inner join cat.FrecuenciaPago f on pr.frecuencia_pago_id_vacaciones =  f.id
		where pr.id =@idproyecto ) 
		
--select @diasbases 

-- buscamos historico
declare @existehistorico int
set @existehistorico = (select COUNT(*) from pl.Planilla_Cabecera 
where  proyecto_id = @idproyecto  and  vacacion  = 1  ) 
declare @Diainicial int
declare @Anoinicial int
declare @mesdescrip varchar(2)

if (@existehistorico = 0)
begin 
	print  'primera planilla'
	set @inicial  = (select CONVERT(varchar(10), @fecha_inicial_vacaciones,112) from cat.Proyecto  where id = @idproyecto )
	if @diasbases  =30 or @diasbases  = 31
     begin
       set @Diainicial = (select DATEPART(day,@fecha_inicial_vacaciones) from cat.Proyecto  where id = @idproyecto )
	   set @Anoinicial = (select DATEPART(year,@fecha_inicial_vacaciones) from cat.Proyecto  where id = @idproyecto )
	   if (DATEPART(month,@inicial) < 10)
		begin
		 set @mesdescrip =  '0'+ CAST(DATEPART(month,@inicial) as varchar(2))
		end
	    if (DATEPART(month,@inicial) > 9)
		begin
		 set @mesdescrip =   CAST(DATEPART(month,@inicial) as varchar(2))
		end  
	    print 'mensual'
		 set @final =  RTRIM(@Anoinicial) +RTRIM(@mesdescrip) + '01'
	     set @final = (select  CONVERT(varchar(10),DATEADD(DAY,-1,  DATEADD(month,1, @final)),112) )
	 end
	 else
	 begin
	 print 'no mensual '
	   set @final = (select CONVERT(varchar(10),  DATEADD(day,@diasbases-1, fecha_inicial),112) from cat.Proyecto  where id = @idproyecto )
	 end
	select @id as id, CONVERT(varchar(10),@inicial,112) as inicial, CONVERT(varchar(10),@final,112) as  final,
 DATEPART(day,@inicial) as Idia, DATEPART(month,@inicial) as Imes, DATEPART(YEAR ,@inicial) as Ianio
,DATEPART(day,@final) as Fdia, DATEPART(month,@final ) as Fmes, DATEPART(YEAR ,@final ) as Fanio



end
ELSE
BEGIN
	declare @actual bit
	--activo
	 set @actual= (select top 1  activo  from pl.Planilla_Cabecera where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc) 
	                     
    if (@actual  =1)
    BEGIN
    PRINT 'copiamos select de lo existe'
	select top 1 id, CONVERT(varchar(10),fecha_inicio,  112) as inicial,
	CONVERT(varchar(10),fecha_fin,  112) as final,
	DATEPART(day,fecha_inicio) as Idia, DATEPART(month,fecha_inicio) as Imes, DATEPART(YEAR ,fecha_inicio) as Ianio
	,DATEPART(day,fecha_fin) as Fdia, DATEPART(month,fecha_fin ) as Fmes, DATEPART(YEAR ,fecha_fin ) as Fanio
	from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto and  vacacion =1 and activo =1
    END
    ELSE
    
    BEGIN
       if @diasbases  =30 or @diasbases  = 31
       begin
            set @inicial  = (select top 1 CONVERT(varchar(10), fecha_inicio,112) from pl.Planilla_Cabecera where  proyecto_id = @idproyecto 
	                     and  vacacion =1 order by id desc  )
       	    print @inicial
       	    set @Diainicial = (select top 1  DATEPART(day,fecha_inicio) from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc)
	   	    set @Anoinicial = (select top 1  DATEPART(year,fecha_inicio) from pl.Planilla_Cabecera where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc)
	                     
		    if (DATEPART(month,@inicial) < 9)
			begin
			--declare @tempmes int
			--set @tempmes  = DATEPART(month,@inicial)+1
			set @mesdescrip =  '0'+ CAST(DATEPART(month,@inicial)+1 as varchar(2))
			
			
			end
			if (DATEPART(month,@inicial) > 8)
			begin
			print 'aki'
			set @mesdescrip =   CAST(DATEPART(month,@inicial)+1 as varchar(2))
			end 
			if @mesdescrip  =13
			begin
			set @mesdescrip  = '01'
			set @Anoinicial = @Anoinicial +1 
			end
	
			set @inicial  = CONVERT(varchar(10),RTRIM(@Anoinicial)+RTRIM(@mesdescrip)+'01' ,112)
	   	        		set @final =( select top 1 CONVERT(varchar(10),DATEADD(day,-1,(DATEADD(MONTH,1,@inicial))),112)  from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
				  and  vacacion  =1  order by id desc)	        
	       print  @mesdescrip
 		   print 'inical ------------------' +rtrim( @inicial)
           print 'mensual'
            --exec pl.Proxima_Planilla 2,2
	   end               
       else 
       begin
		 print 'NO MENSUAL'
		 -- sumamos los dias base 
			set @inicial =( select top 1 CONVERT(varchar(10),DATEADD(day,@diasbases ,fecha_inicio),112)  from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc) 
			set @final = ( select top 1  CONVERT(varchar(10),DATEADD(day,@diasbases ,fecha_fin),112) from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
	                     and  vacacion =1 order by id desc)
		end                  
	    
		select @id as id, CONVERT(varchar(10),@inicial,112) as inicial, CONVERT(varchar(10),@final,112) as  final
		 ,DATEPART(day,@inicial) as Idia, DATEPART(month,@inicial) as Imes, DATEPART(YEAR ,@inicial) as Ianio
		,DATEPART(day,@final) as Fdia, DATEPART(month,@final ) as Fmes, DATEPART(YEAR ,@final ) as Fanio                   
    END

END

end

GO
alter  procedure [pl].[Ploxima_Planilla_Vacaciones]
(
@idproyecto int
)
as
begin

declare @diasbases int
declare @inicial varchar(10)
declare @final varchar(10)
declare @id int
declare @anticipo bit
declare @UlInicial varchar(10)
declare @UIFinal varchar(10)

--declare @idproyecto int
--set @idproyecto  =2 



set @id = 0
set @diasbases = (select   f.diasbase   from cat.Proyecto 
		pr inner join cat.FrecuenciaPago f on pr.frecuencia_pago_id_vacaciones =  f.id
		where pr.id =@idproyecto ) 
		
--select @diasbases 

-- buscamos historico
declare @existehistorico int
set @existehistorico = (select COUNT(*) from pl.Planilla_Cabecera 
where  proyecto_id = @idproyecto  and  vacacion  = 1  ) 
declare @Diainicial int
declare @Anoinicial int
declare @mesdescrip varchar(2)

if (@existehistorico = 0)
begin 
	print  'primera planilla'
	set @inicial  = (select CONVERT(varchar(10), fecha_inicial_vacaciones,112) from cat.Proyecto  where id = @idproyecto )
	if @diasbases  =30 or @diasbases  = 31
     begin
       set @Diainicial = (select DATEPART(day,fecha_inicial) from cat.Proyecto  where id = @idproyecto )
	   set @Anoinicial = (select DATEPART(year,fecha_inicial) from cat.Proyecto  where id = @idproyecto )
	   if (DATEPART(month,@inicial) < 10)
		begin
		 set @mesdescrip =  '0'+ CAST(DATEPART(month,@inicial) as varchar(2))
		end
	    if (DATEPART(month,@inicial) > 9)
		begin
		 set @mesdescrip =   CAST(DATEPART(month,@inicial) as varchar(2))
		end  
	    print 'mensual'
		 set @final =  RTRIM(@Anoinicial) +RTRIM(@mesdescrip) + '01'
	     set @final = (select  CONVERT(varchar(10),DATEADD(DAY,-1,  DATEADD(month,1, @final)),112) )
	 end
	 else
	 begin
	 print 'no mensual '
	   set @final = (select CONVERT(varchar(10),  DATEADD(day,@diasbases-1, fecha_inicial),112) from cat.Proyecto  where id = @idproyecto )
	 end
	select @id as id, CONVERT(varchar(10),@inicial,112) as inicial, CONVERT(varchar(10),@final,112) as  final,
 DATEPART(day,@inicial) as Idia, DATEPART(month,@inicial) as Imes, DATEPART(YEAR ,@inicial) as Ianio
,DATEPART(day,@final) as Fdia, DATEPART(month,@final ) as Fmes, DATEPART(YEAR ,@final ) as Fanio



end
ELSE
BEGIN
	declare @actual bit
	--activo
	 set @actual= (select top 1  activo  from pl.Planilla_Cabecera where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc) 
	                     
    if (@actual  =1)
    BEGIN
    PRINT 'copiamos select de lo existe'
	select top 1 id, CONVERT(varchar(10),fecha_inicio,  112) as inicial,
	CONVERT(varchar(10),fecha_fin,  112) as final,
	DATEPART(day,fecha_inicio) as Idia, DATEPART(month,fecha_inicio) as Imes, DATEPART(YEAR ,fecha_inicio) as Ianio
	,DATEPART(day,fecha_fin) as Fdia, DATEPART(month,fecha_fin ) as Fmes, DATEPART(YEAR ,fecha_fin ) as Fanio
	from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto and  vacacion =1 and activo =1
    END
    ELSE
    
    BEGIN
       if @diasbases  =30 or @diasbases  = 31
       begin
            set @inicial  = (select top 1 CONVERT(varchar(10), fecha_inicio,112) from pl.Planilla_Cabecera where  proyecto_id = @idproyecto 
	                     and  vacacion =1 order by id desc  )
       	    print @inicial
       	    set @Diainicial = (select top 1  DATEPART(day,fecha_inicio) from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc)
	   	    set @Anoinicial = (select top 1  DATEPART(year,fecha_inicio) from pl.Planilla_Cabecera where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc)
	                     
		    if (DATEPART(month,@inicial) < 9)
			begin
			--declare @tempmes int
			--set @tempmes  = DATEPART(month,@inicial)+1
			set @mesdescrip =  '0'+ CAST(DATEPART(month,@inicial)+1 as varchar(2))
			
			
			end
			if (DATEPART(month,@inicial) > 8)
			begin
			print 'aki'
			set @mesdescrip =   CAST(DATEPART(month,@inicial)+1 as varchar(2))
			end 
			if @mesdescrip  =13
			begin
			set @mesdescrip  = '01'
			set @Anoinicial = @Anoinicial +1 
			end
	
			set @inicial  = CONVERT(varchar(10),RTRIM(@Anoinicial)+RTRIM(@mesdescrip)+'01' ,112)
	   	        		set @final =( select top 1 CONVERT(varchar(10),DATEADD(day,-1,(DATEADD(MONTH,1,@inicial))),112)  from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
				  and  vacacion  =1  order by id desc)	        
	       print  @mesdescrip
 		   print 'inical ------------------' +rtrim( @inicial)
           print 'mensual'
            --exec pl.Proxima_Planilla 2,2
	   end               
       else 
       begin
		 print 'NO MENSUAL'
		 -- sumamos los dias base 
			set @inicial =( select top 1 CONVERT(varchar(10),DATEADD(day,@diasbases ,fecha_inicio),112)  from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
	                     and  vacacion =1  order by id desc) 
			set @final = ( select top 1  CONVERT(varchar(10),DATEADD(day,@diasbases ,fecha_fin),112) from pl.Planilla_Cabecera  where  proyecto_id = @idproyecto 
	                     and  vacacion =1 order by id desc)
		end                  
	    
		select @id as id, CONVERT(varchar(10),@inicial,112) as inicial, CONVERT(varchar(10),@final,112) as  final
		 ,DATEPART(day,@inicial) as Idia, DATEPART(month,@inicial) as Imes, DATEPART(YEAR ,@inicial) as Ianio
		,DATEPART(day,@final) as Fdia, DATEPART(month,@final ) as Fmes, DATEPART(YEAR ,@final ) as Fanio                   
    END

END

end


GO
alter procedure  [pl].[PeriodoVacacionPagada]
(
 @proyectoid int,
 @tipoplanillaid int,
 @empleadoid int,
 @periodo int  out
)
as
--set @proyectoid =2 
--set @tipoplanillaid  = 2
--set @empleadoid  = 7 



declare @historico int
declare @dias_vacaciones  int
set @dias_vacaciones  =  (select isnull(dias_vacaciones,1)  from rh.Empleado where id = @empleadoid)
print 'inicia '
declare @asignado int 
set @historico  = (select COUNT(*) from pl.Empleado_Vacacion  pl 
		inner join pl.Empleado_Vacacion_Pagada_Periodo  pag on pl.id = pag.empleado_vacacion_id 
		where rh_empleado_id  = @empleadoid   and tipo_planilla_id  = @tipoPlanillaId  
		and proyecto_id  = @proyectoId  )
print '-------------'						
print @historico
print '-------------'


IF @historico  > 0
BEGIN
set @periodo  = (select top 1 periodo from pl.Empleado_Vacacion_Pagada_Periodo order by id desc  ) 
set @asignado  = (select COUNT(*) from pl.Empleado_Vacacion  pl 
		inner join pl.Empleado_Vacacion_Pagada_Periodo  pag on pl.id = pag.empleado_vacacion_id 
		where rh_empleado_id  = @empleadoid   and tipo_planilla_id  = @tipoPlanillaId  
		and proyecto_id  = @proyectoId  and pag.periodo = @periodo)
if (@asignado  >= @dias_vacaciones)		
 begin
 set @periodo = @periodo  +1
 end		   
END
ELSE
BEGIN
print ' primera '
--set @periodo  = (select YEAR(fecha_alta) from rh.Empleado_Proyecto   
--where empleado_id  = @empleadoid and tipo_planilla_id = @tipoplanillaid 
--and proyecto_id = @proyectoid and activo =1 )
set @periodo  = (select top 1 periodo from pl.Empleado_Vacacion where rh_empleado_id  = @empleadoid 
and tipo_planilla_id = @tipoplanillaid and proyecto_id = @proyectoid 
order by id desc )
END




--select @periodo  as periodo

GO

alter  procedure  [pl].[PeriodoVacacionGozada]
(
 @proyectoid int,
 @tipoplanillaid int,
 @empleadoid int,
 @periodo int   out
)
as
begin
--set @proyectoid =2 
--set @tipoplanillaid  = 2
--set @empleadoid  = 7 
declare @historico int
declare @dias_vacaciones  int
set @dias_vacaciones  =  (select isnull(dias_vacaciones,1)  from rh.Empleado where id = @empleadoid)
declare @asignado int 
set @historico  = (select COUNT(*) from pl.Empleado_Vacacion  pl 
		inner join pl.Empleado_Vacacion_Gozada_Periodo   pag on pl.id = pag.empleado_vacacion_id 
		where rh_empleado_id  = @empleadoid   and tipo_planilla_id  = @tipoPlanillaId  
		and proyecto_id  = @proyectoId  )

print '-------------'						
print @historico
print '-------------'
IF @historico  > 0
BEGIN
	set @periodo  = (select top 1 periodo from pl.Empleado_Vacacion_Gozada_Periodo  order by id desc  ) 
	set @asignado  = (select COUNT(*) from pl.Empleado_Vacacion  pl 
		inner join pl.Empleado_Vacacion_Gozada_Periodo   pag on pl.id = pag.empleado_vacacion_id 
		where rh_empleado_id  = @empleadoid   and tipo_planilla_id  = @tipoPlanillaId  
		and proyecto_id  = @proyectoId  and pag.periodo = @periodo)
		print  'asignados  gozd' + rtrim(@asignado)		
	if (@asignado  >= @dias_vacaciones)		
	begin
		set @periodo = @periodo  +1
	end		   
END
ELSE
BEGIN
--set @periodo  = (select YEAR(fecha_alta) from rh.Empleado_Proyecto   
--where empleado_id  = @empleadoid and tipo_planilla_id = @tipoplanillaid 
--and proyecto_id = @proyectoid and activo =1 )
set @periodo  = (select top 1 periodo from pl.Empleado_Vacacion where rh_empleado_id  = @empleadoid 
and tipo_planilla_id = @tipoplanillaid and proyecto_id = @proyectoid 
order by id desc )

END


end


GO


alter procedure [pl].[PeriodoVacacionCompleta]
(
@idvacacion int,
 @iniciaempleado date,
 @idplanilla int out
)
as

declare @ano varchar(4)
declare @inicioplanilla varchar(10)
declare @finplanilla varchar(10)
declare @mes int

declare @numero int
declare @proyecto int
declare @empleadoProyectoid int
declare @montovacaciones numeric(9,2)
declare @diavacaciones int

declare @sueldobase numeric(9,2)



declare @tipoPlanilla  int = (select tipo_planilla_id  from pl.Empleado_Vacacion where id = @idvacacion )

set @proyecto  = (select proyecto_id   from pl.Empleado_Vacacion where id = @idvacacion )
--set @iniciaempleado  = (select fecha_inicio     from pl.Empleado_Vacacion where id = @idvacacion )
set @montovacaciones   = (select monto    from pl.Empleado_Vacacion where id = @idvacacion )
set @diavacaciones   = (select dias   from pl.Empleado_Vacacion where id = @idvacacion )
--set @empleadoProyectoid  = (select id from rh.Empleado_Proyecto  where empleado_id = @empleado_id
--and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)

----set @sueldobase = (select salario  from rh.Empleado_Proyecto  where empleado_id = @empleado_id
--and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)


--declare @fechainicio  date =  (select fecha_inicio   from pl.Empleado_Vacacion where id = @idvacacion )
declare @frecuenciapago int 
set @frecuenciapago  = (select  frecuencia_pago_id  from rh.Tipo_Planilla  where  id = @tipoPlanilla )
declare @diasbase int
set @diasbase  = (select diasbase  from cat.FrecuenciaPago  where id = @frecuenciapago)
--set @diasbase =30
declare @mesdescrip varchar(2)
declare @fechainicio date =  @iniciaempleado

--select @fechainicio as ini
set @ano = YEAR(@fechainicio)
set @mes = MONTH(@fechainicio)

if (DATEPART(month,@fechainicio ) < 10)
begin
 set @mesdescrip =  '0'+ CAST(DATEPART(month,@fechainicio ) as varchar(2))
end
if (DATEPART(month,@fechainicio ) > 9)
begin
 set @mesdescrip =   CAST(DATEPART(month,@fechainicio ) as varchar(2))
end 		
set @inicioplanilla  = @ano + @mesdescrip+'01'  
if ((DAY(@iniciaempleado ) >=15) and (@diasbase =15))
begin
set @inicioplanilla  = @ano + @mesdescrip+'16'  
end 


if @diasbase =30 or @diasbase  = 31
begin
declare @llevaanticipo bit
set @llevaanticipo = (select usa_anticipo_quincenal   from rh.Tipo_Planilla  where id = @tipoPlanilla  )
set @llevaanticipo =0
set @finplanilla =(select CONVERT(varchar(10),( DATEADD (day,-1 ,(  DATEADD(month, 1, @inicioplanilla)))),112))
   if @llevaanticipo  =1
   begin
    if (DAY(@iniciaempleado ) <=15)
    begin
      set @finplanilla   = @ano + @mesdescrip+'15'   
    end 
   end
end
else
begin
set @finplanilla =( select CONVERT(varchar(10),(DATEADD(day, @diasbase, @inicioplanilla)),112)) 


   if @diasbase   =15
   begin
    if (DAY(@iniciaempleado ) <=15)
    begin
      set @finplanilla   = @ano + @mesdescrip+'15'   
    end 
   end
   
   
end


if ((DAY(@iniciaempleado ) >=15) and (@diasbase =15))
begin
declare @primermes date
set @primermes = @ano + @mesdescrip+'01'
set @finplanilla =(select CONVERT(varchar(10),( DATEADD (day,-1 ,(  DATEADD(month, 1, @primermes)))),112))
end 



declare @existe int
declare @planilla_cabeceraid int

set @existe = (select COUNT(*) from pl.Planilla_Cabecera  where fecha_inicio = @inicioplanilla 
and fecha_fin  = @finplanilla and tipo_planilla_id =@tipoPlanilla  and proyecto_id = @proyecto 
and vacacion =1)		
		

if (@existe >0)
begin
set @planilla_cabeceraid  = (select id from pl.Planilla_Cabecera  where fecha_inicio = @inicioplanilla 
and fecha_fin  = @finplanilla and tipo_planilla_id =@tipoPlanilla  and proyecto_id = @proyecto 
and vacacion =1 and completa_vaca=1)		

set @idplanilla = @planilla_cabeceraid 
end
else
begin 
insert into pl.Planilla_Cabecera 
(proyecto_id, tipo_planilla_id , ano,mes, 
fecha_inicio, fecha_fin , actualiza_libro_salarios, 
activo,anticipo, numero, vacacion,bono,aguinaldo, historico,
created_at, updated_at,created_by, updated_by ,completa_vaca  ) 
values(@proyecto, @tipoPlanilla , @ano,@mes, 
@inicioplanilla , @finplanilla ,0,1,0,1,1,0,0,0,
GETDATE(), GETDATE(),'','',1 )
set @planilla_cabeceraid = (select MAX(id) from pl.Planilla_Cabecera )
set  @idplanilla = (select MAX(id) from pl.Planilla_Cabecera )
end


GO

go
alter procedure [pl].[PeriodoVacacion]
(
@idvacacion int,
 @iniciaempleado date,
 @idplanilla int out
)
as

declare @ano varchar(4)
declare @inicioplanilla varchar(10)
declare @finplanilla varchar(10)
declare @mes int

declare @numero int
declare @proyecto int
declare @empleadoProyectoid int
declare @montovacaciones numeric(9,2)
declare @diavacaciones int

declare @sueldobase numeric(9,2)



declare @tipoPlanilla  int = (select tipo_planilla_id  from pl.Empleado_Vacacion where id = @idvacacion )

set @proyecto  = (select proyecto_id   from pl.Empleado_Vacacion where id = @idvacacion )
--set @iniciaempleado  = (select fecha_inicio     from pl.Empleado_Vacacion where id = @idvacacion )
set @montovacaciones   = (select monto    from pl.Empleado_Vacacion where id = @idvacacion )
set @diavacaciones   = (select dias   from pl.Empleado_Vacacion where id = @idvacacion )
--set @empleadoProyectoid  = (select id from rh.Empleado_Proyecto  where empleado_id = @empleado_id
--and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)

----set @sueldobase = (select salario  from rh.Empleado_Proyecto  where empleado_id = @empleado_id
--and tipo_planilla_id = @tipoPlanilla  and proyecto_id = @proyecto)


--declare @fechainicio  date =  (select fecha_inicio   from pl.Empleado_Vacacion where id = @idvacacion )
declare @frecuenciapago int 
set @frecuenciapago  = (select  frecuencia_pago_id  from rh.Tipo_Planilla  where  id = @tipoPlanilla )
set @frecuenciapago=1
declare @diasbase int
set @diasbase  = (select diasbase  from cat.FrecuenciaPago  where id = @frecuenciapago)
set @diasbase=30
declare @mesdescrip varchar(2)
declare @fechainicio date =  @iniciaempleado

--select @fechainicio as ini
set @ano = YEAR(@fechainicio)
set @mes = MONTH(@fechainicio)

if (DATEPART(month,@fechainicio ) < 10)
begin
 set @mesdescrip =  '0'+ CAST(DATEPART(month,@fechainicio ) as varchar(2))
end
if (DATEPART(month,@fechainicio ) > 9)
begin
 set @mesdescrip =   CAST(DATEPART(month,@fechainicio ) as varchar(2))
end 		
set @inicioplanilla  = @ano + @mesdescrip+'01'  


if @diasbase =30 or @diasbase  = 31
begin
declare @llevaanticipo bit
set @llevaanticipo = (select usa_anticipo_quincenal   from rh.Tipo_Planilla  where id = @tipoPlanilla  )
set @llevaanticipo =0
set @finplanilla =(select CONVERT(varchar(10),( DATEADD (day,-1 ,(  DATEADD(month, 1, @inicioplanilla)))),112))
   if @llevaanticipo  =1
   begin
    if (DAY(@iniciaempleado ) <=15)
    begin
      set @finplanilla   = @ano + @mesdescrip+'15'   
    end 
   end
end
else
begin
set @finplanilla =( select CONVERT(varchar(10),(DATEADD(day, @diasbase, @inicioplanilla)),112)) 
end

declare @existe int
declare @planilla_cabeceraid int

set @existe = (select COUNT(*) from pl.Planilla_Cabecera  where fecha_inicio = @inicioplanilla 
and fecha_fin  = @finplanilla and tipo_planilla_id =@tipoPlanilla  and proyecto_id = @proyecto 
and vacacion =1)		
		

if (@existe >0)
begin
set @planilla_cabeceraid  = (select id from pl.Planilla_Cabecera  where fecha_inicio = @inicioplanilla 
and fecha_fin  = @finplanilla and tipo_planilla_id =@tipoPlanilla  and proyecto_id = @proyecto 
and vacacion =1)		

set @idplanilla = @planilla_cabeceraid 
end
else
begin 
insert into pl.Planilla_Cabecera 
(proyecto_id, tipo_planilla_id , ano,mes, 
fecha_inicio, fecha_fin , actualiza_libro_salarios, 
activo,anticipo, numero, vacacion,bono,aguinaldo, historico,
created_at, updated_at,created_by, updated_by   ) 
values(@proyecto, @tipoPlanilla , @ano,@mes, 
@inicioplanilla , @finplanilla ,0,1,0,1,1,0,0,0,
GETDATE(), GETDATE(),'','')
set @planilla_cabeceraid = (select MAX(id) from pl.Planilla_Cabecera )
set  @idplanilla = (select MAX(id) from pl.Planilla_Cabecera )
end		
		


GO

alter  procedure [pl].[IniciaPlanillaVacacion]
(
@id int, 
@proyecto_id int, 
@fecha_inicio date, 
@fecha_fin date, 
@usuario varchar(32) 
)
as
begin

declare @ano int 
declare @mes int
set @ano = DATEPART(YEAR, @fecha_inicio)
set @mes = DATEPART(MONTH, @fecha_inicio)  



if @id =0
	begin
	INSERT INTO pl.Planilla_Cabecera
           ( proyecto_id
           , ano
           , mes
           , fecha_inicio
           , fecha_fin
           , actualiza_libro_salarios
           , activo
           , created_by
           , updated_by
           , created_at
           , updated_at
           , anticipo,vacacion )
     VALUES
           (@proyecto_id, 
           @ano,  
           @mes,  
           @fecha_inicio,  
           @fecha_fin,  
           1, 
           1, 
           @usuario, 
           @usuario,
           GETDATE(),
           GETDATE(),  
           0,1)
         set @id = (select MAX(id) from pl.Planilla_Cabecera)   
end

select @id  

end


GO

alter procedure [pl].[IEmpleado_Vacacion]
 (
 @rh_empleado_id int, 
 @proyecto_id int, 
 @tipo_planilla_id int, 
 @fecha_inicio varchar(10), 
 @diasIng numeric(9,2), 
 @monto numeric(9,2), 
 @descripcion varchar(32), 
 @pagada bit, 
 @gozada bit,
 @usuario varchar(32),
 @fecha_fin varchar(10) ,
 @sabado  bit,
 @inicia_nedio_dia bit,
 @fin_medio_dia bit,
 @diaspaga numeric(9,2),
 @periodoin int
 )

as
declare @horasdia int
declare @horasinserta int
set @horasdia  = (select top 1  f.horasdia     from rh.Empleado_Proyecto pr
inner join rh.Tipo_Planilla  tip
on pr.tipo_planilla_id   =tip.id
inner join cat.FrecuenciaPago  f
on f.id = tip.frecuencia_pago_id  
where empleado_id  =  @rh_empleado_id and pr.activo  = 1)

set @horasdia = ISNULL(@horasdia, 8)
set @horasinserta  = @horasdia 
declare @bonificacion bit
declare @ingresos  bit
declare @horas_extras bit 
declare @metodo varchar(50)
declare @calculo varchar(50)

set @bonificacion = ( select    bonificacion_vacaciones   
     from cat.Proyecto where id = @proyecto_id )
set @ingresos  = ( select    ingresos_afectos_vacaciones
     from cat.Proyecto where id = @proyecto_id )
set @horas_extras =  ( select  horas_extras_vacaciones 
     from cat.Proyecto where id = @proyecto_id )
set @metodo =  ( select   metodo_vacaciones 
     from cat.Proyecto where id = @proyecto_id )
set @calculo =
( select    calculo_vacaciones
     from cat.Proyecto where id = @proyecto_id )

declare @fechainiciopla  date
declare @fechafinpla  date

set @fechainiciopla = (select top 1  CONVERT(varchar(10), fecha_inicio ,112)   from pl.Planilla_Cabecera c
inner join pl.Planilla_Resumen r
on c.id = r.planilla_cabecera_id 
where anticipo   = 0 and isnull(vacacion,0) =0 and
empleado_id  = @rh_empleado_id   and 
 isnull(aguinaldo ,0) =0  and isnull(bono ,0) =0
 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id  = @proyecto_id 
order by fecha_inicio desc) 




INSERT INTO pl .Empleado_Vacacion 
(rh_empleado_id,proyecto_id,tipo_planilla_id,fecha_inicio,dias,monto 
,descripcion,pagada,gozada,created_by,updated_by,created_at 
,updated_at, estado, fecha_fin, medio_dia_sabado, inicia_medio_dia, fin_medio_dia, diaspaga,
metodo_vacaciones, calculo_vacaciones, ingresos_afectos_vacaciones ,horas_extras,
bonificacion_vacaciones ,fecha_inicio_planilla,periodo  )
     VALUES
(@rh_empleado_id,@proyecto_id,  @tipo_planilla_id, @fecha_inicio,@diasIng , @monto,  
@descripcion, @pagada, @gozada,  @usuario ,  @usuario ,  GETDATE(),  
GETDATE(), 'Pendiente', @fecha_fin, @sabado, @inicia_nedio_dia , @fin_medio_dia, @diaspaga,
@metodo, @calculo, @ingresos , @horas_extras ,
@bonificacion , @fechainiciopla ,@periodoin )






declare @empleado_vacacion_id int
set @empleado_vacacion_id  = (select MAX(id) from pl.Empleado_Vacacion )
declare @fechadia date
declare @conte int
declare @periodo int 
declare @contadordos int 


-- HISTORICO PLANILLA
if @gozada  =1 
BEGIN
	set @conte = 0
	while (@conte < (@diasIng ))
		begin
		--set @horasinserta  = @horasdia 
		--if @conte  = 0 and @inicia_nedio_dia =1
		--begin
		--set @horasinserta  = @horasdia /2
		--end
	 --   set @contadordos  = @conte +1
		--if @contadordos  = @dias  and @fin_medio_dia =1
		--begin
		--set @horasinserta  = @horasdia /2
		--end
		
		set @fechadia  = (DATEADD(DAY,@conte,@fecha_inicio))
		exec   pl.PeriodoVacacionGozada  @proyecto_id,  @tipo_planilla_id,@rh_empleado_id, @periodo OUT
		print 'perido gozada ' + rtrim(@periodo)
		insert into pl.Empleado_Vacacion_Gozada_Periodo (empleado_vacacion_id, dia, activo, periodo, horas )
		values(@empleado_vacacion_id, @fechadia,1, @periodo,@horasdia  ) 
		set @conte  = @conte  +1
	end
END

if @pagada   =1 
BEGIN
	set @conte = 0
	while (@conte < (@diasIng))
		begin
		--set @horasinserta  = @horasdia 
		--if @conte  = 0 and @inicia_nedio_dia =1
		--begin
		--set @horasinserta  = @horasdia /2
		--end
	 --   set @contadordos  = @conte +1
		--if @contadordos  = @dias  and @fin_medio_dia =1
		--begin
		--set @horasinserta  = @horasdia /2
		--end		
		set @fechadia  = (DATEADD(DAY,@conte,@fecha_inicio)) 
		exec   pl.PeriodoVacacionPagada  @proyecto_id,  @tipo_planilla_id,@rh_empleado_id, @periodo OUT
		print 'perido pagada ' + rtrim(@periodo)
	
		insert into pl.Empleado_Vacacion_Pagada_Periodo (empleado_vacacion_id, dia, activo,periodo , horas)
		values(@empleado_vacacion_id, @fechadia,1, @periodo,  @horasdia    ) 
		set @conte  = @conte  +1
	end
END


-- CALCULO PLANILLA
declare @montodiario numeric(9,2)
declare @dias numeric(9,2)
--set @dias =DATEDIFF(day, @fecha_inicio , @fecha_fin ) + 1
set @dias = @diaspaga  
set @montodiario  = @monto / @dias 

if @gozada  =1 
BEGIN
	set @conte = 0
	while (@conte < (@dias))
		begin
		set @horasinserta  = @horasdia 
		if @conte  = 0 and @inicia_nedio_dia =1
		begin
		set @horasinserta  = @horasdia /2
		end
	    set @contadordos  = @conte +1
		if @contadordos  = @dias  and @fin_medio_dia =1
		begin
		set @horasinserta  = @horasdia /2
		end		
		set @fechadia  = (DATEADD(DAY,@conte,@fecha_inicio))
		exec   pl.PeriodoVacacionGozada  @proyecto_id,  @tipo_planilla_id,@rh_empleado_id, @periodo OUT
		print 'perido gozada ' + rtrim(@periodo)
		insert into pl.Empleado_Vacacion_Gozada(empleado_vacacion_id, dia, activo, periodo, horas)
		values(@empleado_vacacion_id, @fechadia,1, @periodo, @horasinserta    ) 
		set @conte  = @conte  +1
	end
END

if @pagada   =1 
BEGIN
	set @conte = 0
	while (@conte < (@dias))
		begin
		set @horasinserta  = @horasdia 
		if @conte  = 0 and @inicia_nedio_dia =1
		begin
		set @horasinserta  = @horasdia /2
		end
	    set @contadordos  = @conte +1
		if @contadordos  = @dias  and @fin_medio_dia =1
		begin
		set @horasinserta  = @horasdia /2
		end		
		set @fechadia  = (DATEADD(DAY,@conte,@fecha_inicio)) 
		exec   pl.PeriodoVacacionPagada  @proyecto_id,  @tipo_planilla_id,@rh_empleado_id, @periodo OUT
		print 'perido pagada ' + rtrim(@periodo)
	
		insert into pl.Empleado_Vacacion_Pagada(empleado_vacacion_id, dia, activo,periodo,monto_dia, horas )
		values(@empleado_vacacion_id, @fechadia,1, @periodo, @montodiario, @horasinserta   ) 
		set @conte  = @conte  +1
	end

declare @existe int

set @existe = (select COUNT(*) from pl.Empleado_Vacacion_Resumen
where empleado_id = @rh_empleado_id  and proyecto_id =  @proyecto_id  and tipo_planilla_id  = @tipo_planilla_id)

if (@existe  =0)
begin
exec pl.VistaResumenEmpleadoVacacionResumen @rh_empleado_id, @proyecto_id,@tipo_planilla_id,3
update  pl.Empleado_Vacacion_Resumen set pagado = derecho
where empleado_id = @rh_empleado_id  and proyecto_id =  @proyecto_id  and tipo_planilla_id  = @tipo_planilla_id
and Periodo < @periodoin
update  pl.Empleado_Vacacion_Resumen set pagado = derecho
where empleado_id = @rh_empleado_id  and proyecto_id =  @proyecto_id and tipo_planilla_id  = @tipo_planilla_id
and Periodo < @periodoin
update  pl.Empleado_Vacacion_Resumen set Pagado  = @diasIng  
where empleado_id = @rh_empleado_id  and proyecto_id =  @proyecto_id  and tipo_planilla_id  = @tipo_planilla_id
and Periodo = @periodoin 
end
else
begin
declare @nuevo  int
set @nuevo  = (select COUNT(*)  from pl.Empleado_Vacacion_Resumen
where empleado_id = @rh_empleado_id  and proyecto_id =  @proyecto_id  and tipo_planilla_id  = @tipo_planilla_id
and Periodo = @periodoin )
if (@nuevo > 0)
	begin
		declare @antes numeric(9,2)
		set @antes = (select Pagado  from pl.Empleado_Vacacion_Resumen
		where empleado_id = @rh_empleado_id  and proyecto_id =  @proyecto_id  and tipo_planilla_id  = @tipo_planilla_id
		and Periodo = @periodoin and Nuevo  =0)	
		declare @nuevovalor numeric(9,2)
		set @nuevovalor  = @antes + @diasIng 
		update  pl.Empleado_Vacacion_Resumen set Pagado  = @nuevovalor 
		where empleado_id = @rh_empleado_id  and proyecto_id =  @proyecto_id  and tipo_planilla_id  = @tipo_planilla_id
		and Periodo = @periodoin 
	end
    else
    begin
    
    declare @derecho int = (select dias_vacaciones  from rh.Empleado  where id = @rh_empleado_id )
    insert into pl.Empleado_Vacacion_Resumen
        (empleado_id,    proyecto_id,  tipo_planilla_id ,  Periodo,  
         Pagado,Derecho,Nuevo, created_by, created_at)
   values(@rh_empleado_id, @proyecto_id, @tipo_planilla_id, @periodoin, 
         @dias,  @derecho,1, '', GETDATE())         
    end


end
--update  pl.Empleado_Vacacion_Resumen set Pagado =3

END

select ' Vacaciones de Empleado ingresadas con exito'



GO

alter PROCEDURE [pl].[ICIngreso_Detalle_Vacaciones]
(
 @planillaresumen  varchar(10),
 @idempleado int,
 @tipoplanilla int,
 @proyectoid int,
 @usuario varchar(32),
 @fecha varchar(10)
)
as
--#PENDIENTE VALIDAR LA FECHA DE INICIO
begin
	declare @centrocosto varchar(40)
    set @centrocosto  = ''
	create table  #tableresultado (tipoingreso integer, valor  numeric(9,2),empleado_id int, id_detalle int, cabecera_id int)
	--set @idempleado = 5
	--set @tipoplanilla =1
	--set @proyectoid  = 2
-- NORMALES
	insert into #tableresultado(tipoingreso,valor ,empleado_id,id_detalle, cabecera_id ) 
	select  tipo_ingreso_id,  valor, empleado_id,0,id from rh.Empleado_Ingreso where 
	--tipo_planilla_id  = @tipoplanilla  and
	 proyecto_id  = @proyectoid
	  and empleado_id = @idempleado and especial = 0 and activo  = 1 and fecha <= @fecha 
---EMPLEADO  ESPECIALES
	select  CAST (id as varchar(10))  as idingreso, IDENTITY(int,1,1) as id, tipo_ingreso_id 
	into #temporalingreso   from rh.Empleado_Ingreso where 
    --tipo_planilla_id  = @tipoplanilla  and 
    proyecto_id  = @proyectoid 
     and empleado_id = @idempleado and especial = 1 and fecha <= @fecha 
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
		from rh.Empleado_Ingreso_Detalle  where empleado_ingreso_id = @iding order by id desc  
	end
	drop table #temporalingreso 
	
	INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
	,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
	columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle, cabecera_id   )
	select @planillaresumen, 'Ingreso',descripcion,tem.tipoingreso, tip.cuenta_contable,
	@centrocosto, '+', tem.valor,0, tem.valor, 1,@usuario, @usuario, 
	GETDATE(), GETDATE(),tip.agregar_columna,tip.orden, incluye_isr, tip.afecta_ss,  afecta_prestaciones ,
    tem.id_detalle, cabecera_id from #tableresultado tem inner join cat.Tipo_Ingreso  tip 
    on tem.tipoingreso  = tip.id
    and icluye_vacaciones  = 1

	
	drop table #tableresultado
end



--select * from cat.Tipo_Ingreso   where afecta_ss  = 1

GO

alter procedure [pl].[EliminaCalculoVacacion]
(
@empleadoid int,
@proyectoid int,
@planillaid int

)
as


declare @idpendiente int 
-- busca id
set @idpendiente  = (select id   from pl.empleado_vacacion where estado  = 'Pendiente'
and rh_empleado_id = @empleadoid  and proyecto_id =@proyectoid  and tipo_planilla_id  =@planillaid )
set @idpendiente  = ISNULL(@idpendiente,0)
-- elimiina detalles
delete from pl.Empleado_Vacacion_Gozada  where empleado_vacacion_id  = @idpendiente 
delete from pl.Empleado_Vacacion_Pagada  where empleado_vacacion_id  = @idpendiente 
delete from pl.Empleado_Vacacion_Gozada_Periodo   where empleado_vacacion_id  = @idpendiente 
delete from pl.Empleado_Vacacion_Pagada_Periodo  where empleado_vacacion_id  = @idpendiente 

-- elimina peridos nuevos
delete from pl.Empleado_Vacacion_Resumen  where empleado_id = @empleadoid
and proyecto_id =@proyectoid  and tipo_planilla_id  =@planillaid  and Nuevo  = 1


-- si existe el id 
if @idpendiente  > 0
begin
-- busca dias y el periodo para retora
declare @dias  int = (select dias  from pl.Empleado_Vacacion where id = @idpendiente )
declare @periodo int = (select  periodo  from pl.Empleado_Vacacion where id = @idpendiente ) 

declare @pagados numeric(9,2) =(select   Pagado   from pl.Empleado_Vacacion_Resumen  
								where empleado_id = @empleadoid and proyecto_id =@proyectoid 
								 and tipo_planilla_id  =@planillaid  and Periodo = @periodo)
set @pagados  = ISNULL(@pagados,0)
set @dias = ISNULL(@dias,0)

declare @regresa numeric(9,2)
set @regresa   = @pagados  - @dias 
-- actualiza el regreso
 update  pl.Empleado_Vacacion_Resumen   set Pagado  = @regresa 
		where empleado_id = @empleadoid and proyecto_id =@proyectoid 
	 and tipo_planilla_id  =@planillaid  and Periodo = @periodo


end
-- elimina tabla final

delete from pl.Empleado_Vacacion  where id = @idpendiente

GO
alter  procedure [pl].[DiasVacacionesPlanillaCompleta]
(
  @fechainicia varchar(10),
  @fechafin  varchar(10),
  @idvacacion int,
  @empleado_id int,
  @proyecto_id int,
  @fechaout date out
  )

as
BEGIN
declare @sumadias int =17

declare @fechafinVaca varchar(10)
set @fechafinVaca = (select CONVERT(varchar(10),DATEADD(day,@sumadias,fecha_inicio)  , 112) from pl.Empleado_Vacacion where id =@idvacacion )
set @fechaout  = @fechafinVaca  

--select @fechaout  as fechaout
if @fechafinVaca  >= @fechafin
begin
set @fechaout = @fechafin 
end



END

GO

alter  procedure [pl].[DiasVacacionesPlanilla]
(
  @fechainicia varchar(10),
  @fechafin  varchar(10),
  @idvacacion int,
  @empleado_id int,
  @proyecto_id int,
  @fechaout date out
  )

as
BEGIN


declare @fechafinVaca varchar(10)
set @fechafinVaca = (select CONVERT(varchar(10), fecha_fin , 112) from pl.Empleado_Vacacion where id =@idvacacion )
set @fechaout  = @fechafinVaca  
if @fechafinVaca  >= @fechafin
begin
set @fechaout = @fechafin 
end


END

GO
alter  procedure [pl].[DiasVacacionesFecha]
(
  @fechainicia varchar(10),
  @fechafin  varchar(10),
  @horasdiarias int,
  @empleado_id int,
  @proyecto_id int,
  @fechaout date out
  )

as
BEGIN
set @fechaout  = @fechainicia 
declare @totaldias numeric(9,2) =0
declare @totalconteo numeric(9,2) =0

--DECLARE  @totalausencias numeric(9,2)   
--declare @totaldias numeric(9,2) =0
--declare @totalconteo numeric(9,2) =0


select top 5 rh_empleado_id,  fecha_inicio, dias,
IDENTITY(int,1,1) as reg  into #barre 
from pl.Empleado_Vacacion  where estado ='Aceptado'
and rh_empleado_id = @empleado_id 
--and MONTH(fecha_inicio) = 
order by id desc 
declare @cantiferiado int=0
declare @canti int =0
declare @cantoc int =0
while (@cantoc  <=(select MAX(reg) from #barre))
BEGIN
set @cantoc = @cantoc +1
select * into #temporal from #barre where reg = @cantoc


create table #temporalfecha(fecha date)
declare @fechainicio date =(select fecha_inicio  from #temporal)
declare @dias numeric(9,2) =(select dias from #temporal)
--set @dias = 8.5

 if @dias >= 1
  begin
   declare @conte int =0
   declare @contadordias int =0
   while (@conte < @dias -(@dias % 2))
   begin
     declare @fechav date
     set @fechav =(select DATEADD(day, @contadordias , @fechainicio))
     
     ---*** fecha *** CAMBIAR CONT POR VALIDAR DIA COMPLETO
     declare @existe int
     set @existe = (select COUNT(*) from diaferiado where fecha = @fechav)
     declare @fechar varchar(15) =( select CONVERT(varchar(10), @fechav ,102))
     set @fechar= replace(@fechar, '.','')
     set @conte = @conte +1
     set @contadordias = @contadordias +1
     if (@fechar >= @fechainicia ) and (@fechar <=@fechafin)
     begin
     set @canti = @canti+1
     print '----------------------'
     print @fechar 
     print @fechainicia
     print @fechafin
     print @canti
     print '----------------------'
       --if (@existe =0)
       --begin
         set @totalconteo = @totalconteo +1
       --end 
       --else
       --begin
       --print 'feriado'
       --print @fechav
       --end
     
     end
     
     if (@existe =1)
     begin
         set @contadordias = @contadordias +1
         set @fechav =(select DATEADD(day, @contadordias , @fechainicio))
         --set @fechar  =( select CONVERT(varchar(10), @fechav ,102))
         --set @fechar= replace(@fechar, '.','')
         --set @conte = @conte +1
         --if (@fechar >= @fechainicia ) and (@fechar <=@fechafin)
         begin
            set @cantiferiado = @cantiferiado+1
            print '*********************'
            print @fechar 
            print @fechainicia
            print @fechafin
            print @cantiferiado
            print '*****************'
            set @totalconteo = @totalconteo +1
          end
       end
     
     
     
   end
-- residuo 
   if ((@dias % 2) > 0)
   begin
   set @totalconteo = @totalconteo +@dias % 2
    end
end


  set @fechav =(select DATEADD(day, @totalconteo , @fechainicio))
--select @fechav  as fi
set  @fechaout  = @fechav
--select @fechaout   as fou
--select @totalconteo
drop table  #temporalfecha
drop table #temporal 
end
END




GO

alter  procedure [pl].[DiasVacaciones]
(
  @fechainicia varchar(10),
  @fechafin  varchar(10),
  @horasdiarias int,
  @empleado_id int,
  @proyecto_id int,
  @totalausencias numeric(9,2) out
  )

as
BEGIN

set @totalausencias = (
select COUNT(*) from pl.detalleVacacion
where proyecto_id =@proyecto_id and empleado_id =@empleado_id
and fecha >= @fechainicia  and fecha <= @fechafin  and medio_dia =0
)

declare @mediodia numeric(9,2)
set @mediodia  = (
select COUNT(*) from pl.detalleVacacion
where proyecto_id =@proyecto_id and empleado_id =@empleado_id
and fecha >= @fechainicia  and fecha <= @fechafin  and medio_dia =1
)
set @mediodia   = ISNULL(@mediodia  , 0) 

if @mediodia >0
begin
set @mediodia = @mediodia /2
end

set @totalausencias  = ISNULL(@totalausencias , 0) 


set @totalausencias = @totalausencias +@mediodia 


--if @empleado_id = 1724
--begin
--set @totalausencias=0
--end
END




GO

alter  procedure [pl].[CargaHistoricoVacaciones]
(

 @fechaalta date, -- = '20150105'
 @periodo int, --  = 2016
@diacompleto varchar(6) , -- = '1.5'
 @codigo  varchar(10)  -- = 114
)
as
BEGIN
declare @rh_empleado_id int = (select empleado_id from rh.Empleado_Proyecto where codigo = @codigo)
declare @proyecto_id int =17
declare @tipo_planilla_id int =13

 --update rh.Empleado_Proyecto set codigo  = 'PRA-136' where id = 2617
 --update rh.Empleado_Proyecto set codigo  = 'PRB-136' where id = 2616 
 -- update rh.Empleado_Proyecto set codigo  = 'PRA-137' where id = 2618
set @diacompleto= REPLACE(@diacompleto, '.50','.5')
 set @diacompleto= REPLACE(@diacompleto, '.00','')
set @diacompleto= REPLACE(@diacompleto, '.0','')
declare @diasPeriodo int = 0
declare @residuo int =0
if  SUBSTRING(@diacompleto ,2,1) ='.' or (SUBSTRING(@diacompleto ,3,1) ='.')
begin
  set @diasPeriodo =REPLACE(@diacompleto, '.5','')
  set @residuo='5'
end
else
begin
  set @diasPeriodo = @diacompleto
end


declare @fecha_inicio date
declare @empleado_vacacion_id  int
declare @anoinicio int = year(@fechaalta)
declare @ano int = @anoinicio
declare @contador int =0
declare @fechadia date = getdate()
DECLARE @PERIODOINSERTA INT = @periodo
while (@ano <=(@periodo-1))
BEGIN
	set  @PERIODOINSERTA  =year(DATEADD(year,@contador, @fechaalta))
	select @ano, 15, DATEADD(year,@contador, @fechaalta)
	set @ano = @ano +1
	set @fecha_inicio = DATEADD(DAY, 1,( DATEADD(year,@contador, @fechaalta)))
    -- PERIODO ATRAZADO
	INSERT INTO  pl.Empleado_Vacacion  (rh_empleado_id ,proyecto_id ,tipo_planilla_id   ,fecha_inicio  ,dias,monto,descripcion,pagada
           ,gozada,created_by,updated_by ,created_at,updated_at ,estado,fecha_fin,
           medio_dia_sabado  ,inicia_medio_dia,fin_medio_dia
           ,diaspaga ,metodo_vacaciones  ,calculo_vacaciones,
           ingresos_afectos_vacaciones ,bonificacion_vacaciones,horas_extras ,fecha_inicio_planilla ,periodo)
     VALUES (@rh_empleado_id, @proyecto_id, @tipo_planilla_id,@fecha_inicio, 15, 0, 'Vacacion Empleado', 
           1,  1, 'Admin', 'Admin', GETDATE(), GETDATE(), 'Aceptado',  @fecha_inicio, 
           0,  0,  0, 15, 'Percibido (Pagado Real)','Ultimo Sueldo', 
           0,  0,  0, @fecha_inicio,   @PERIODOINSERTA ) 
            
      insert into pl.Empleado_Vacacion_Resumen 
	  ( empleado_id, proyecto_id , tipo_planilla_id ,
	  Periodo, Derecho, Pagado, Nuevo, created_at , created_by )
	  values (@rh_empleado_id, @proyecto_id, @tipo_planilla_id ,
	  @PERIODOINSERTA, 15, 15,0, GETDATE(), GETDATE())    
   
      set @empleado_vacacion_id = (select MAX(id) from pl.Empleado_Vacacion)            
      DECLARE @CONTADORDIA INT =0
      WHILE (@CONTADORDIA <15)  
      BEGIN
        SET @CONTADORDIA  = @CONTADORDIA+1
        DECLARE @FECHAINSERTA DATE =  DATEADD(DAY, @CONTADORDIA,( DATEADD(year,@contador, @fechaalta)))
        ------------ vacac--------
        insert into pl.Empleado_Vacacion_Gozada_Periodo
        (empleado_vacacion_id, dia, activo, periodo,monto, horas)
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTA as dia,0 as activo, @PERIODOINSERTA as periodo, 0  as monto, 8 as horas
  
        insert into   pl.Empleado_Vacacion_Gozada 
        (empleado_vacacion_id, dia, activo, periodo ,horas)
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTA as dia,0 as activo, @PERIODOINSERTA as periodo, 8 as horas
  
        insert into pl.Empleado_Vacacion_Pagada(
        empleado_vacacion_id, dia, activo , periodo, monto_dia, horas)
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTA as dia,0 as activo, @periodo as periodo, 0  as monto, 8 as horas

        insert into  pl.Empleado_Vacacion_Pagada_Periodo(  empleado_vacacion_id, dia, activo, periodo,horas  )
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTA as dia,0 as activo, @periodo as periodo,  8 as horas
 
END
      set @contador = @contador+1
END

select @periodo, @diasPeriodo, DATEADD(year,@contador, @fechaalta)
DECLARE @CONTADORFINAL INT =0
if  (@CONTADORFINAL <@diasPeriodo)
BEGIN
      set @PERIODOINSERTA = @PERIODOINSERTA+1
      set @fecha_inicio = DATEADD(DAY, 1,( DATEADD(year,@contador, @fechaalta)))
      ----- CABECERA
     INSERT INTO  pl.Empleado_Vacacion  (rh_empleado_id ,proyecto_id ,tipo_planilla_id   ,fecha_inicio  ,dias,monto,descripcion,pagada
     ,gozada,created_by,updated_by ,created_at,updated_at ,estado,fecha_fin,
     medio_dia_sabado  ,inicia_medio_dia,fin_medio_dia
     ,diaspaga ,metodo_vacaciones  ,calculo_vacaciones,
     ingresos_afectos_vacaciones ,bonificacion_vacaciones,horas_extras ,fecha_inicio_planilla ,periodo)
     VALUES
           (@rh_empleado_id, @proyecto_id, @tipo_planilla_id,@fecha_inicio,@diasPeriodo, 0, 'Vacacion Empleado Ult.', 
           1,  1, 'Admin', 'Admin', GETDATE(), GETDATE(), 'Aceptado',  @fecha_inicio, 
           0,  0,  0, 
            @diasPeriodo, 'Carga Inicial','Carga Inicial', 
            0,  0,  0, @fecha_inicio,   @PERIODOINSERTA )
            
            
         insert into pl.Empleado_Vacacion_Resumen 
			( empleado_id, proyecto_id , tipo_planilla_id ,
			Periodo, Derecho, Pagado, Nuevo, created_at , created_by )
			values (@rh_empleado_id, @proyecto_id, @tipo_planilla_id ,
			@PERIODOINSERTA, 15, @diasPeriodo,0, GETDATE(), GETDATE())      
            
     set @empleado_vacacion_id = (select MAX(id) from pl.Empleado_Vacacion) 
     WHILE (@CONTADORFINAL <@diasPeriodo)
     BEGIN          
     SET @CONTADORFINAL  = @CONTADORFINAL+1
     DECLARE @FECHAINSERTAFIN DATE =  DATEADD(DAY, @CONTADORFINAL,( DATEADD(year,@contador, @fechaalta)))
       insert into pl.Empleado_Vacacion_Gozada_Periodo
       (empleado_vacacion_id, dia, activo, periodo,monto, horas)
      --  from pl.Empleado_Vacacion_Gozada_Periodo
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTAFIN as dia,0 as activo, @PERIODOINSERTA as periodo, 0  as monto, 8 as horas
        insert into   pl.Empleado_Vacacion_Gozada 
        ( empleado_vacacion_id, dia, activo, periodo ,horas)
      --  from pl.Empleado_Vacacion_Gozada
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTAFIN as dia,0 as activo, @PERIODOINSERTA as periodo, 8 as horas
        insert into pl.Empleado_Vacacion_Pagada(
        empleado_vacacion_id, dia, activo , periodo, monto_dia, horas)
        --  from pl.Empleado_Vacacion_Pagada
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTAFIN as dia,0 as activo, @PERIODOINSERTA as periodo, 0  as monto, 8 as horas
        insert into  pl.Empleado_Vacacion_Pagada_Periodo(  empleado_vacacion_id, dia, activo, periodo,horas  )
        --from pl.Empleado_Vacacion_Pagada_Periodo
        SELECT @empleado_vacacion_id as empleado_vacacion_id,
        @FECHAINSERTAFIN as dia,0 as activo, @PERIODOINSERTA as periodo,  8 as horas
  END
END

if (@residuo > 0)
begin
------- CABECERA
set @fecha_inicio = DATEADD(DAY, 1,( DATEADD(year,@contador, @fechaalta)))
----- CABECERA
     INSERT INTO  pl.Empleado_Vacacion  (rh_empleado_id ,proyecto_id ,tipo_planilla_id   ,fecha_inicio  ,dias,monto,descripcion,pagada
           ,gozada,created_by,updated_by ,created_at,updated_at ,estado,fecha_fin,
           medio_dia_sabado  ,inicia_medio_dia,fin_medio_dia
           ,diaspaga ,metodo_vacaciones  ,calculo_vacaciones,
           ingresos_afectos_vacaciones ,bonificacion_vacaciones,horas_extras ,fecha_inicio_planilla ,periodo)
      VALUES
           (@rh_empleado_id, @proyecto_id, @tipo_planilla_id,@fecha_inicio, 0.5, 0, 'Vacacion Empleado R.', 
           1,  1, 'Admin', 'Admin', GETDATE(), GETDATE(), 'Aceptado',  @fecha_inicio, 
            0,  0,  0, 0.5, 'Carga Inicial','Carga Inicial', 
            0,  0,  0, @fecha_inicio,   @PERIODOINSERTA )
            
            declare @existe int 
            set @existe =  (select id from  pl.Empleado_Vacacion_Resumen  where empleado_id=@rh_empleado_id
            and periodo = @periodo )
            set @existe = ISNULL(@existe, 0)
            if (@existe=0)
            begin
              insert into pl.Empleado_Vacacion_Resumen (empleado_id, proyecto_id ,
              tipo_planilla_id ,  Periodo, Derecho, Pagado, Nuevo, created_at , created_by )
              values (@rh_empleado_id, @proyecto_id, @tipo_planilla_id ,
              @PERIODOINSERTA, 15, 0.5,0, GETDATE(), GETDATE()) 
            end
            else 
            begin
            declare @pagado int =  (select Pagado  from  pl.Empleado_Vacacion_Resumen  where empleado_id=@rh_empleado_id
            and periodo = @periodo )
            update pl.Empleado_Vacacion_Resumen  set Pagado = @pagado+0.5 where id = @existe 
            
            end
            select * from  pl.Empleado_Vacacion_Resumen
            
	  --    insert into pl.Empleado_Vacacion_Resumen 
	  --    ( empleado_id, proyecto_id , tipo_planilla_id ,
   --Periodo, Derecho, Pagado, Nuevo, created_at , created_by )
   --values (@rh_empleado_id, @proyecto_id, @tipo_planilla_id ,
   --@PERIODOINSERTA, 15, 15,0, GETDATE(), GETDATE()) 
               
            
            
    set @empleado_vacacion_id = (select MAX(id) from pl.Empleado_Vacacion) 
    DECLARE @CONTADORFINALRE INT =0
    WHILE (@CONTADORFINALRE <@diasPeriodo)
    BEGIN
      SET @CONTADORFINALRE  = @CONTADORFINALRE+2
      DECLARE @FECHAINSERTAFINRE DATE =  DATEADD(DAY, @CONTADORFINALRE,( DATEADD(year,@contador, @fechaalta)))
      insert into pl.Empleado_Vacacion_Gozada_Periodo
      (empleado_vacacion_id, dia, activo, periodo,monto, horas)
      SELECT @empleado_vacacion_id as empleado_vacacion_id,
      @FECHAINSERTAFINRE as dia,0 as activo, @PERIODOINSERTA as periodo, 0  as monto, 4 as horas
 
     insert into   pl.Empleado_Vacacion_Gozada 
     ( empleado_vacacion_id, dia, activo, periodo ,horas)
      SELECT @empleado_vacacion_id as empleado_vacacion_id,
      @FECHAINSERTAFINRE as dia,0 as activo, @PERIODOINSERTA as periodo, 4 as horas
 
      insert into pl.Empleado_Vacacion_Pagada(
      empleado_vacacion_id, dia, activo , periodo, monto_dia, horas)
      SELECT @empleado_vacacion_id as empleado_vacacion_id,
      @FECHAINSERTAFINRE as dia,0 as activo, @periodo as periodo, 0  as monto, 4 as horas
 
      insert into  pl.Empleado_Vacacion_Pagada_Periodo(  empleado_vacacion_id, dia, activo, periodo,horas  )
      SELECT @empleado_vacacion_id as empleado_vacacion_id,
      @FECHAINSERTAFINRE as dia,0 as activo, @periodo as periodo,  4 as horas
END
end

END

GO

alter PROCEDURE  [pl].[CalculoRetiroVacaciones]
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
declare @bonVacaciones int
declare @horasVacaciones int
declare @ingresosvacaciones int
declare @metodo varchar(100) -- devengado percibido
declare @dias_vacaciones_paga numeric(9,2)
declare @fechabaja date
declare @calcular_base_vacaciones varchar(100)

SET @metodo = (select metodo from #detalleEmpleado )
SET @IDEMPLEADO = (select  empleado_id from #detalleEmpleado )
SET @proyecto_id =(select proyecto_id from #detalleEmpleado )
SET @tipo_planilla_id =(select tipo_planilla_id from #detalleEmpleado )
SET @bonVacaciones  = (select bonificacion_vacaciones from #detalleEmpleado )
SET @horasVacaciones  = (select horas_vacaciones from #detalleEmpleado )
SET @ingresosvacaciones  =(select ingresos_vacaciones from #detalleEmpleado )
set @dias_vacaciones_paga = (select dias_vacaciones_paga from #detalleEmpleado)
set @fechabaja  = (select fecha_baja from #detalleEmpleado)
set @calcular_base_vacaciones = (select calcular_base_vacaciones from #detalleEmpleado)
drop table  #detalleEmpleado 

DECLARE @diasdercho int
set @diasdercho  = (select isnull(dias_vacaciones,0)  from rh.Empleado  where id = @IDEMPLEADO )


declare @SALARIO numeric(9,2)
EXEC pl.SalarioEmpleado @IDEMPLEADO,@proyecto_id ,@tipo_planilla_id ,@SALARIO OUT
declare @BONIFICACION numeric(9,2)
SET @BONIFICACION = (select  isnull(bono_base,0)  from rh.Empleado_Proyecto  where empleado_id  = @IDEMPLEADO  
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)                   

DECLARE @fecha_inicio date
set @fecha_inicio  =(select top 1  fecha_inicio  
from 
-- pl.Planilla_Cabecera  ca inner join pl.Planilla_Resumen re on re.planilla_cabecera_id  = ca.id
pl.VW_PLANILLA 
where empleado_id  = @IDEMPLEADO 
and proyecto_id  = @proyecto_id and tipo_planilla_id  = @tipo_planilla_id 
and anticipo  = 0 and activo = 0 
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 
order by fecha_inicio  desc )


--/// METODO DE  PROMEDIO ULTIMO SEIS MESES
-- --Promedio Doce Meses
--   'Ultimo Sueldo' 
--  'Promedio Seis Meses' 
--- SUMAMOS LOS MONTOS DE LAS PLANILLAS AFECTADAS 
--- **************** FILTRAR FECHAS
declare @mesesresta int
set @mesesresta=0

declare @cantidadplanilla int 
set @cantidadplanilla  = (
select count(*) from 
-- pl.Planilla_Resumen r inner join pl.Planilla_Cabecera c  on c.id = r.planilla_cabecera_id  
pl.VW_PLANILLA 
where tipo_planilla_id  = @tipo_planilla_id  and empleado_id  = @IDEMPLEADO 
and proyecto_id  = @proyecto_id  and anticipo  = 0 and activo = 0 
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 )



--/// METODO DE  PROMEDIO ULTIMO SEIS MESES
if ((@calcular_base_vacaciones= 'Promedio Doce Meses' ) and (@cantidadplanilla >= 12 ))
begin
set @mesesresta=-11
end

if (@calcular_base_vacaciones= 'Promedio Seis Meses' ) and (@cantidadplanilla >= 6 )
begin
set @mesesresta=-5
end
print @calcular_base_vacaciones
print @mesesresta
--- SUMAMOS LOS MONTOS DE LAS PLANILLAS AFECTADAS
declare @fecha_fin date 
set @fecha_fin  = DATEADD(MONTH ,@mesesresta, @fecha_inicio)


--select  p.empleado_id,    (dias_base) as dias_base,
--(dias_laborados) as dias_laborados,  (p.sueldo_base) as sueldo_base, 
--(bonificacion_base) as bonificacion_base, 
--(sueldo_base_recibido) as sueldo_base_recibido,
--(bonificacion_base_recibido) as bonificacion_base_recibido,
--(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
--(total_extras) as total_extras     from pl.Planilla_Resumen  p
--inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
--where p.empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
--and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
--and ISNULL(vacacion,0) = 0
--and ISNULL(aguinaldo,0)=0
--and ISNULL(bono,0) = 0 
--and fecha_inicio <= @fecha_inicio  
--and fecha_inicio >= @fecha_fin 
--group by empleado_id 



--select @fecha_inicio , @fecha_fin

select top 6 empleado_id,    sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados,  sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras into #todos  from 
-- pl.Planilla_Resumen  p inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
pl.VW_PLANILLA  c
where empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 
and fecha_inicio <= @fecha_inicio  
--and fecha_inicio >= @fecha_fin 
group by empleado_id 
--order by fecha_inicio  desc

--select * from #todos 

--select * from #todos 

--select  p.empleado_id,    dias_base as dias_base,
--dias_laborados as dias_laborados,  p.sueldo_base as sueldo_base, 
--bonificacion_base as bonificacion_base, 
--sueldo_base_recibido as sueldo_base_recibido,
--bonificacion_base_recibido as bonificacion_base_recibido,
--ingresos_afectos_prestaciones  as ingresos_afectos_prestaciones, 
--total_extras as total_extras  from pl.Planilla_Resumen   p
--inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
--where p.empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
--and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
--and ISNULL(vacacion,0) = 0
--and ISNULL(aguinaldo,0)=0
--and ISNULL(bono,0) = 0 
--and fecha_inicio <= @fecha_inicio  
--and fecha_inicio >= @fecha_fin 

DECLARE @DIASLABORADOS numeric(9,2)= (select   dias_laborados  from #todos)
DECLARE @DIASBASE numeric(9,2)= (select   dias_base  from #todos)
DECLARE @SALARIOBASE numeric(9,2)  = (select   sueldo_base  from #todos)
DECLARE @BONIFICACIONBASE  numeric(9,2)  = (select   bonificacion_base  from #todos)
DECLARE @SALARIORECIBIDA  numeric(9,2)  = (select   sueldo_base_recibido  from #todos)
DECLARE @BONIFICACIONRECIBIDA  numeric(9,2)  = (select bonificacion_base_recibido     from #todos)
DECLARE @EXTRAS numeric(9,2)  = (select   total_extras  from #todos)
DECLARE @INGRESOS numeric(9,2)   =0  -- (select   ingresos_afectos_prestaciones  from #todos)
SET @INGRESOS = (SELECT  ISNULL(SUM( ingresos_afectos_prestaciones),0)  FROM 
--PL.Planilla_Resumen  
pl.VW_PLANILLA  WHERE empleado_id =@IDEMPLEADO) /6
--select @ingresos

DECLARE @MONTOPERCIBIDO numeric(9,2) 
DECLARE @MONTODEVENGADO numeric(9,2)
DECLARE @DIARECIBIDO numeric(9,2)
DECLARE @DIADEVENGADO numeric(9,2)
declare @montomensual numeric (9,2)
declare @montodiario numeric(9,2)
declare @TOTALG numeric(9,2)
declare @diarioIN numeric(9,2)

set @MONTOPERCIBIDO =  @SALARIORECIBIDA   
set @MONTODEVENGADO  = @SALARIOBASE
-- BONIFICACION  
IF @bonVacaciones  = 1
BEGIN
set @MONTODEVENGADO  = @MONTODEVENGADO  + @BONIFICACIONBASE 
set @MONTOPERCIBIDO  = @MONTOPERCIBIDO  + @BONIFICACIONRECIBIDA 
END
-- HORAS EXTRAS
if @horasVacaciones  =1
begin
set @MONTODEVENGADO  = @MONTODEVENGADO  + @EXTRAS 
set @MONTOPERCIBIDO  = @MONTOPERCIBIDO  + @EXTRAS  
end
-- INGRESOS AFECTOS
--if @ingresosvacaciones  =1
--begin
set @MONTODEVENGADO  = @MONTODEVENGADO  + @INGRESOS  
set @MONTOPERCIBIDO  = @MONTOPERCIBIDO  + @INGRESOS 
--end

-- UTILIZAMOS EL PERCIBIDO O DEVENGADO
if RTRIM(@metodo)  = 'Devengado (Contratacion)'
BEGIN
set @TOTALG  = @MONTODEVENGADO 
set @TOTALG  = @MONTODEVENGADO 
SET @DIADEVENGADO  = (@MONTODEVENGADO) /@DIASBASE 
set @diarioIN = (@MONTODEVENGADO) /@DIASBASE
set @montodiario = @DIADEVENGADO 
end
else
begin
set @TOTALG  = @MONTOPERCIBIDO 
--select * from #todos
select @metodo as metodo
set @DIASLABORADOS = @DIASBASE 
select @MONTOPERCIBIDO, @DIASLABORADOS 
SET @DIARECIBIDO  = (@MONTOPERCIBIDO)   /@DIASLABORADOS  
set @diarioIN = (@MONTOPERCIBIDO)   /@DIASLABORADOS
set @montodiario = @DIARECIBIDO 
select @montodiario as monto_diario
end



set @montodiario= @montodiario + @INGRESOS

--  VALOR DIARIO 
print '--------------addddddd'
print @montodiario 

set @montomensual  = @montodiario  * @DIASMES 

drop table #todos


declare @valorvacaciones  numeric(9,2)
if RTRIM(@metodo)  = 'Devengado (Contratacion)'
BEGIN
SET @montodiario = (@TOTALG / ((@mesesresta *-1) +1))
set @valorvacaciones = (@TOTALG / ((@mesesresta *-1) +1))
select @valorvacaciones as valovacaiones
set @valorvacaciones = @valorvacaciones / @DIASMES 
select @valorvacaciones as valorvac, @DIASMES as diav 


set @valorvacaciones  =@valorvacaciones  * @dias_vacaciones_paga 
select @valorvacaciones as valo, @dias_vacaciones_paga as diavaca
end
else
begin

set @valorvacaciones = @dias_vacaciones_paga
end

declare @montodiariofin numeric(9,2)

set  @montodiariofin = (select diario from pl.Empleado_Retiro_Detalle where rtrim(Tipo)='Indemizacion'
           and Empleado_Retiro_Id = @IDRETIRO )
           
set  @montodiariofin = ISNULL( @montodiariofin,0)
if  @montodiariofin >0
begin
set @montodiario =@montodiariofin
end

set @valorvacaciones = @montodiario *  @dias_vacaciones_paga  


--set @valorvacaciones=0

--,@DIASMES,  @dias_vacaciones_paga
  
--select @valorvacaciones   
--SET @valorvacaciones  = (@montodiario /@DIASPERIODO ) *@dias_vacaciones_paga  
--select @TOTALG, @metodo 
--select @valorvacaciones


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
@fecha_inicio,@fecha_fin   
 
end




--exec pl.CalculoRetiroVacaciones 49,''
--select * from pl.Empleado_Retiro_Detalle  where Empleado_Retiro_Id =49 and Tipo ='vacaciones'

GO
alter PROCEDURE  [pl].[CalculoRetiroVacaciones]
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
declare @bonVacaciones int
declare @horasVacaciones int
declare @ingresosvacaciones int
declare @metodo varchar(100) -- devengado percibido
declare @dias_vacaciones_paga numeric(9,2)
declare @fechabaja date
declare @calcular_base_vacaciones varchar(100)

SET @metodo = (select metodo from #detalleEmpleado )
SET @IDEMPLEADO = (select  empleado_id from #detalleEmpleado )
SET @proyecto_id =(select proyecto_id from #detalleEmpleado )
SET @tipo_planilla_id =(select tipo_planilla_id from #detalleEmpleado )
SET @bonVacaciones  = (select bonificacion_vacaciones from #detalleEmpleado )
SET @horasVacaciones  = (select horas_vacaciones from #detalleEmpleado )
SET @ingresosvacaciones  =(select ingresos_vacaciones from #detalleEmpleado )
set @dias_vacaciones_paga = (select dias_vacaciones_paga from #detalleEmpleado)
set @fechabaja  = (select fecha_baja from #detalleEmpleado)
set @calcular_base_vacaciones = (select calcular_base_vacaciones from #detalleEmpleado)
drop table  #detalleEmpleado 

DECLARE @diasdercho int
set @diasdercho  = (select isnull(dias_vacaciones,0)  from rh.Empleado  where id = @IDEMPLEADO )


declare @SALARIO numeric(9,2)
EXEC pl.SalarioEmpleado @IDEMPLEADO,@proyecto_id ,@tipo_planilla_id ,@SALARIO OUT
declare @BONIFICACION numeric(9,2)
SET @BONIFICACION = (select  isnull(bono_base,0)  from rh.Empleado_Proyecto  where empleado_id  = @IDEMPLEADO  
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)                   

DECLARE @fecha_inicio date
set @fecha_inicio  =(select top 1  fecha_inicio  
from 
-- pl.Planilla_Cabecera  ca inner join pl.Planilla_Resumen re on re.planilla_cabecera_id  = ca.id
pl.VW_PLANILLA 
where empleado_id  = @IDEMPLEADO 
and proyecto_id  = @proyecto_id and tipo_planilla_id  = @tipo_planilla_id 
and anticipo  = 0 and activo = 0 
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 
order by fecha_inicio  desc )


--/// METODO DE  PROMEDIO ULTIMO SEIS MESES
-- --Promedio Doce Meses
--   'Ultimo Sueldo' 
--  'Promedio Seis Meses' 
--- SUMAMOS LOS MONTOS DE LAS PLANILLAS AFECTADAS 
--- **************** FILTRAR FECHAS
declare @mesesresta int
set @mesesresta=0

declare @cantidadplanilla int 
set @cantidadplanilla  = (
select count(*) from 
-- pl.Planilla_Resumen r inner join pl.Planilla_Cabecera c  on c.id = r.planilla_cabecera_id  
pl.VW_PLANILLA 
where tipo_planilla_id  = @tipo_planilla_id  and empleado_id  = @IDEMPLEADO 
and proyecto_id  = @proyecto_id  and anticipo  = 0 and activo = 0 
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 )



--/// METODO DE  PROMEDIO ULTIMO SEIS MESES
if ((@calcular_base_vacaciones= 'Promedio Doce Meses' ) and (@cantidadplanilla >= 12 ))
begin
set @mesesresta=-11
end

if (@calcular_base_vacaciones= 'Promedio Seis Meses' ) and (@cantidadplanilla >= 6 )
begin
set @mesesresta=-5
end
print @calcular_base_vacaciones
print @mesesresta
--- SUMAMOS LOS MONTOS DE LAS PLANILLAS AFECTADAS
declare @fecha_fin date 
set @fecha_fin  = DATEADD(MONTH ,@mesesresta, @fecha_inicio)


--select  p.empleado_id,    (dias_base) as dias_base,
--(dias_laborados) as dias_laborados,  (p.sueldo_base) as sueldo_base, 
--(bonificacion_base) as bonificacion_base, 
--(sueldo_base_recibido) as sueldo_base_recibido,
--(bonificacion_base_recibido) as bonificacion_base_recibido,
--(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
--(total_extras) as total_extras     from pl.Planilla_Resumen  p
--inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
--where p.empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
--and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
--and ISNULL(vacacion,0) = 0
--and ISNULL(aguinaldo,0)=0
--and ISNULL(bono,0) = 0 
--and fecha_inicio <= @fecha_inicio  
--and fecha_inicio >= @fecha_fin 
--group by empleado_id 



--select @fecha_inicio , @fecha_fin

select top 6 empleado_id,    sum(dias_base) as dias_base,
sum(dias_laborados) as dias_laborados,  sum(sueldo_base) as sueldo_base, 
sum(bonificacion_base) as bonificacion_base, 
sum(sueldo_base_recibido) as sueldo_base_recibido,
sum(bonificacion_base_recibido) as bonificacion_base_recibido,
sum(ingresos_afectos_prestaciones)  as ingresos_afectos_prestaciones, 
sum(total_extras) as total_extras into #todos  from 
-- pl.Planilla_Resumen  p inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
pl.VW_PLANILLA  c
where empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
and ISNULL(vacacion,0) = 0
and ISNULL(aguinaldo,0)=0
and ISNULL(bono,0) = 0 
and fecha_inicio <= @fecha_inicio  
--and fecha_inicio >= @fecha_fin 
group by empleado_id 
--order by fecha_inicio  desc

--select * from #todos 

--select * from #todos 

--select  p.empleado_id,    dias_base as dias_base,
--dias_laborados as dias_laborados,  p.sueldo_base as sueldo_base, 
--bonificacion_base as bonificacion_base, 
--sueldo_base_recibido as sueldo_base_recibido,
--bonificacion_base_recibido as bonificacion_base_recibido,
--ingresos_afectos_prestaciones  as ingresos_afectos_prestaciones, 
--total_extras as total_extras  from pl.Planilla_Resumen   p
--inner join pl.Planilla_Cabecera c on p.planilla_cabecera_id  = c.id  
--where p.empleado_id  = @IDEMPLEADO  and c.proyecto_id  = @proyecto_id  
--and c.tipo_planilla_id  = @tipo_planilla_id   and c.anticipo  = 0
--and ISNULL(vacacion,0) = 0
--and ISNULL(aguinaldo,0)=0
--and ISNULL(bono,0) = 0 
--and fecha_inicio <= @fecha_inicio  
--and fecha_inicio >= @fecha_fin 

DECLARE @DIASLABORADOS numeric(9,2)= (select   dias_laborados  from #todos)
DECLARE @DIASBASE numeric(9,2)= (select   dias_base  from #todos)
DECLARE @SALARIOBASE numeric(9,2)  = (select   sueldo_base  from #todos)
DECLARE @BONIFICACIONBASE  numeric(9,2)  = (select   bonificacion_base  from #todos)
DECLARE @SALARIORECIBIDA  numeric(9,2)  = (select   sueldo_base_recibido  from #todos)
DECLARE @BONIFICACIONRECIBIDA  numeric(9,2)  = (select bonificacion_base_recibido     from #todos)
DECLARE @EXTRAS numeric(9,2)  = (select   total_extras  from #todos)
DECLARE @INGRESOS numeric(9,2)   =0  -- (select   ingresos_afectos_prestaciones  from #todos)
SET @INGRESOS = (SELECT  ISNULL(SUM( ingresos_afectos_prestaciones),0)  FROM 
--PL.Planilla_Resumen  
pl.VW_PLANILLA  WHERE empleado_id =@IDEMPLEADO) /6
--select @ingresos

DECLARE @MONTOPERCIBIDO numeric(9,2) 
DECLARE @MONTODEVENGADO numeric(9,2)
DECLARE @DIARECIBIDO numeric(9,2)
DECLARE @DIADEVENGADO numeric(9,2)
declare @montomensual numeric (9,2)
declare @montodiario numeric(9,2)
declare @TOTALG numeric(9,2)
declare @diarioIN numeric(9,2)

set @MONTOPERCIBIDO =  @SALARIORECIBIDA   
set @MONTODEVENGADO  = @SALARIOBASE
-- BONIFICACION  
IF @bonVacaciones  = 1
BEGIN
set @MONTODEVENGADO  = @MONTODEVENGADO  + @BONIFICACIONBASE 
set @MONTOPERCIBIDO  = @MONTOPERCIBIDO  + @BONIFICACIONRECIBIDA 
END
-- HORAS EXTRAS
if @horasVacaciones  =1
begin
set @MONTODEVENGADO  = @MONTODEVENGADO  + @EXTRAS 
set @MONTOPERCIBIDO  = @MONTOPERCIBIDO  + @EXTRAS  
end
-- INGRESOS AFECTOS
--if @ingresosvacaciones  =1
--begin
set @MONTODEVENGADO  = @MONTODEVENGADO  + @INGRESOS  
set @MONTOPERCIBIDO  = @MONTOPERCIBIDO  + @INGRESOS 
--end

-- UTILIZAMOS EL PERCIBIDO O DEVENGADO
if RTRIM(@metodo)  = 'Devengado (Contratacion)'
BEGIN
set @TOTALG  = @MONTODEVENGADO 
set @TOTALG  = @MONTODEVENGADO 
SET @DIADEVENGADO  = (@MONTODEVENGADO) /@DIASBASE 
set @diarioIN = (@MONTODEVENGADO) /@DIASBASE
set @montodiario = @DIADEVENGADO 
end
else
begin
set @TOTALG  = @MONTOPERCIBIDO 
--select * from #todos
select @metodo as metodo
set @DIASLABORADOS = @DIASBASE 
select @MONTOPERCIBIDO, @DIASLABORADOS 
SET @DIARECIBIDO  = (@MONTOPERCIBIDO)   /@DIASLABORADOS  
set @diarioIN = (@MONTOPERCIBIDO)   /@DIASLABORADOS
set @montodiario = @DIARECIBIDO 
select @montodiario as monto_diario
end



set @montodiario= @montodiario + @INGRESOS

--  VALOR DIARIO 
print '--------------addddddd'
print @montodiario 

set @montomensual  = @montodiario  * @DIASMES 

drop table #todos


declare @valorvacaciones  numeric(9,2)
if RTRIM(@metodo)  = 'Devengado (Contratacion)'
BEGIN
SET @montodiario = (@TOTALG / ((@mesesresta *-1) +1))
set @valorvacaciones = (@TOTALG / ((@mesesresta *-1) +1))
select @valorvacaciones as valovacaiones
set @valorvacaciones = @valorvacaciones / @DIASMES 
select @valorvacaciones as valorvac, @DIASMES as diav 


set @valorvacaciones  =@valorvacaciones  * @dias_vacaciones_paga 
select @valorvacaciones as valo, @dias_vacaciones_paga as diavaca
end
else
begin

set @valorvacaciones = @dias_vacaciones_paga
end

declare @montodiariofin numeric(9,2)

set  @montodiariofin = (select diario from pl.Empleado_Retiro_Detalle where rtrim(Tipo)='Indemizacion'
           and Empleado_Retiro_Id = @IDRETIRO )
           
set  @montodiariofin = ISNULL( @montodiariofin,0)
if  @montodiariofin >0
begin
set @montodiario =@montodiariofin
end

set @valorvacaciones = @montodiario *  @dias_vacaciones_paga  


--set @valorvacaciones=0

--,@DIASMES,  @dias_vacaciones_paga
  
--select @valorvacaciones   
--SET @valorvacaciones  = (@montodiario /@DIASPERIODO ) *@dias_vacaciones_paga  
--select @TOTALG, @metodo 
--select @valorvacaciones


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
@fecha_inicio,@fecha_fin   
 
end




--exec pl.CalculoRetiroVacaciones 49,''
--select * from pl.Empleado_Retiro_Detalle  where Empleado_Retiro_Id =49 and Tipo ='vacaciones'

GO


GO
alter  procedure [pl].[CalculoPlanillaVacacion]
(
 @planillacabecera int,
 @usuario varchar(50)
 )
 as
 BEGIN
 select top 1   fe.horasbase, 
ss.empleado_porcentaje,  ss.patrono_porcentaje,  ss.intecap_porcentaje, ss.irtra_porcentaje,  
provision_aguinaldo, provision_bono14, provision_indemnizacion, provision_vacaciones, 
dias_calendario, dias_septimo, usa_anticipo_seguro_social,usa_anticipo_bonificacion
into  #tablaVariables1  from rh.Tipo_Planilla  t 
inner join cat.FrecuenciaPago  fe on fe.id = t.frecuencia_pago_id  
inner join cat.Tipo_ss  ss on t.tipo_ss_id = ss.id 
inner join pl.Planilla_Cabecera  pl on t.id = pl.tipo_planilla_id
where pl.id =  @planillacabecera
--select * from #tablaVariables1

declare @empleado_porcentaje numeric(9,2)		SET @empleado_porcentaje = (select empleado_porcentaje from #tablaVariables1 )
declare @patrono_porcentaje numeric(9,2)		SET @patrono_porcentaje = (select patrono_porcentaje from #tablaVariables1 )
declare @intecap_porcentaje  numeric(9,2)		SET @intecap_porcentaje = (select intecap_porcentaje from #tablaVariables1 )
declare @irtra_porcentaje numeric(9,2)			SET @irtra_porcentaje = (select irtra_porcentaje from #tablaVariables1 )


--set @planillacabecera = 108
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
select CONVERT(varchar(10), fecha_inicio ,112) as inicio,CONVERT(varchar(10), fecha_fin ,112)  as fin, proyecto_id 
into  #tablaVariables  from  pl.Planilla_Cabecera  where id = @planillacabecera   
--#region INICIALES PARA CALCULO
declare @fechaini varchar(10)					SET @fechaini = (select inicio from #tablaVariables )
declare @fechafin varchar(10)					SET @fechafin = (select fin from #tablaVariables )
declare @proyecto_id  int                        SET @proyecto_id  = (select proyecto_id  from #tablaVariables )
drop table #tablaVariables

declare @empleado_id  int 
declare @salario numeric (9,2)
declare @tipo_planilla_id int 
declare @idcontrato int
declare @bonificacionbase numeric(9,2)
declare @dias_base int 

select IDENTITY(INT, 1,1) as id,  rh_empleado_id, count(dia) as Ndias,  SUM(monto_dia) as valor,
tipo_planilla_id  
into #vacaciones   from pl.Empleado_Vacacion  vac
inner join pl.Empleado_Vacacion_Pagada  pag
on pag.empleado_vacacion_id  = vac.id
where vac.fecha_inicio  >= @fechaini  and vac.fecha_inicio  < = @fechafin 
and estado  = 'Aceptado'
group by rh_empleado_id ,monto_dia, dias,tipo_planilla_id  


--select * from #vacaciones
declare @cant int
declare @diavacaciones int
declare @montovacaciones numeric(9,2)
DECLARE @total_ingresos   numeric(9,2)
DECLARE @total_descuentos  numeric(9,2)
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
DECLARE @planilla_resumen_id int 
DECLARE @total_sueldo_liquido  numeric(9,2)
set @cant  =1
while(@cant <= (select MAX(id) from #vacaciones))
begin

set @empleado_id  = (select rh_empleado_id from #vacaciones where id = @cant)
set @diavacaciones  = (select Ndias from #vacaciones where Id = @cant)
set @montovacaciones  = (select valor from #vacaciones where id = @cant )

set @tipo_planilla_id = (select tipo_planilla_id from #vacaciones where id = @cant )
set @dias_base = (select dias_vacaciones  from rh.Empleado  where id= @empleado_id)
--print @dias_base 
--print @diavacaciones
--print @montovacaciones 
print @salario

EXEC pl.SalarioEmpleado @empleado_id,@proyecto_id ,@tipo_planilla_id ,@salario OUT

SET @bonificacionbase = (select  isnull(bono_base,0)  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                                 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1) 
                                
 
set @idcontrato = (select  id  from rh.Empleado_Proyecto  where empleado_id  = @empleado_id 
                    and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id = @proyecto_id  and activo =1)



insert into pl.Planilla_Resumen 
(dias_base,sueldo_base,bonificacion_base,salario_base,planilla_cabecera_id,empleado_id,empleado_proyecto_id,
ingresos_ss,ingresos_no_ss,ingresos_isr,ingresos_no_isr,descuento_ss,descuentos_no_ss,descuentos_isr,
descuentos_no_isr,descuento_anticipo_quincena,cant_extras_simples,monto_extras_simples,cant_extras_dobles,
monto_extras_dobles,cant_extras_extendidas,monto_extras_extendidas,ingresos_afectos_prestaciones,
ingresos_no_afectos_prestaciones,sueldo_base_recibido,bonificacion_base_recibido,dias_laborados,
total_ingresos,total_descuentos,total_extras,total_sueldo_liquido,isr,dias_ausencias,observaciones,
activo,created_by,updated_by,created_at,updated_at,septimos,monto_septimos,
pagado_vacaciones,pagado_bonoCatorce,pagado_Aguinaldo,dias_suspendido,dias_vacaciones,monto_vacaciones)
values
(@dias_base, @salario,@bonificacionbase, @salario, @planillacabecera,@empleado_id,@idcontrato,
0,0,0,0,0,0,0,
0,0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,@montovacaciones ,0,0,'',
1,@usuario, @usuario,   getdate(),getdate(),0,0,
1,0,0,0,@diavacaciones, @montovacaciones )      

set @planilla_resumen_id = (select max(id) from pl.Planilla_Resumen) 
--INSERTA SUELDO EN DETALLE
   INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
	,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
	columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
	VALUES (@planilla_resumen_id,'Vacaciones','Vacaciones',-1,'',
	'','+',@montovacaciones ,0,@montovacaciones , 1,@usuario, @usuario,GETDATE(), GETDATE(),
	1,1, 0, 1, 0, 1 )
	


-- CALCULO DE DESCUENTOS
exec pl.ICDescuento_Detalle_vacaciones  @planilla_resumen_id,@empleado_id, @tipo_planilla_id, @proyecto_id, @usuario , @fechaini
select * into #temdes from pl.Planilla_Detalle  where tipo = 'Descuento'  and  planilla_resumen_id  = @planilla_resumen_id
set @descuento_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=1)
set @descuentos_no_ss  = (select isnull(SUM(monto),0) from #temdes where afecta_ss=0)
set @descuentos_isr  = (select isnull(SUM(monto),0) from #temdes where afecta_isr=1)
set  @descuentos_no_isr  = (select isnull(SUM(monto),0) from #temdes where afecta_isr=0)
set @total_descuentos  = @descuento_ss  + @descuentos_no_ss
drop table #temdes


--CALCULO DE INGRESOS
exec pl.ICIngreso_Detalle_Vacaciones @planilla_resumen_id,@empleado_id, @tipo_planilla_id, @proyecto_id, @usuario ,  @fechaini

select * into #teming from pl.Planilla_Detalle  where tipo = 'Ingreso'  and  planilla_resumen_id  = @planilla_resumen_id
set @ingresos_ss = (select isnull(SUM(monto),0) from #teming where afecta_ss=1)
set @ingresos_no_ss = (select isnull(SUM(monto),0) from #teming where afecta_ss=0)
set @ingresos_isr = (select isnull(SUM(monto),0) from #teming where afecta_isr=1)
set  @ingresos_no_isr = (select isnull(SUM(monto),0) from #teming where afecta_isr=0)
set @ingresos_afectos_prestaciones = (select isnull(SUM(monto),0) from #teming where afecta_prestacion=1)
set @ingresos_no_afectos_prestaciones = (select isnull(SUM(monto),0) from #teming where afecta_prestacion=0)
set  @total_ingresos  = @ingresos_ss  + @ingresos_no_ss 
drop table #teming

DECLARE @TotalIngresosAfectosSS numeric(9,2)
DECLARE @SeguroSocialEmpleado numeric(9,2)
DECLARE @irtra numeric(9,2)
DECLARE @intecap numeric(9,2)
DECLARE @SeguroSocialPatronal numeric(9,2)
set @TotalIngresosAfectosSS = @montovacaciones  +@ingresos_ss 

--select @ingresos_ss 
--select @empleado_porcentaje

--select * from cat.Tipo_ss 


set @empleado_porcentaje = ISNULL(@empleado_porcentaje, 4.83)
set  @patrono_porcentaje = ISNULL( @patrono_porcentaje, 10.67)


--select @TotalIngresosAfectosSS
--select @empleado_porcentaje
	SET @SeguroSocialEmpleado  = (@TotalIngresosAfectosSS * @empleado_porcentaje)/100 
	
	--select @SeguroSocialEmpleado 
	SET @SeguroSocialPatronal = (@TotalIngresosAfectosSS * @patrono_porcentaje )/100 
	--SET @irtra   = (@TotalIngresosAfectosSS * @irtra_porcentaje )/100  
	--SET @intecap  = (@TotalIngresosAfectosSS * @intecap_porcentaje  )/100 
	--INSERTA CALCULO SEGURO SOCIAL
	INSERT INTO pl.Planilla_Detalle(planilla_resumen_id,tipo,descripcion,concepto_id,cuenta_contable 
		,centro_costo,identificar,monto,haber,debe,activo,created_by,updated_by,created_at,updated_at,
		columna_activo,orden, afecta_isr, afecta_ss, afecta_prestacion, id_detalle)
			VALUES (@planilla_resumen_id,'Seguro Social','Seguro Social Empleado',0,'',
		'','-',@SeguroSocialEmpleado ,@SeguroSocialEmpleado,0,  1,@usuario, @usuario,GETDATE(), GETDATE(),
		1,2, 0, 1, 0, 1 )
	--@total_sueldo_liquido	@montovacaciones 
print 'antes'
--exec pl.CalculoPlanillaVacacion 134, 'admin'
print @SeguroSocialEmpleado
set @total_sueldo_liquido  = @montovacaciones  + @total_ingresos  - @total_descuentos- @SeguroSocialEmpleado
print @total_sueldo_liquido


-- ACTUALIZAMOS LOS CALCULOS
UPDATE   pl.Planilla_Resumen 
SET ingresos_ss =@ingresos_ss ,ingresos_no_ss =@ingresos_no_ss,
ingresos_isr=@ingresos_isr,ingresos_no_isr=@ingresos_no_isr,
descuento_ss=@SeguroSocialEmpleado,descuentos_no_ss=@descuentos_no_ss,
descuentos_isr=@descuentos_isr,descuentos_no_isr=@descuentos_no_isr,
ingresos_afectos_prestaciones=@ingresos_afectos_prestaciones,
ingresos_no_afectos_prestaciones=@ingresos_no_afectos_prestaciones,

total_ingresos=@total_ingresos,total_descuentos=@total_descuentos,
total_sueldo_liquido=@total_sueldo_liquido 
where id= @planilla_resumen_id 
        
  set @cant = @cant  +1                                                  
end
drop table #tablaVariables1
drop table #vacaciones
select @planillacabecera
END
go
alter  PROCEDURE  [pl].[CalculoPagoVacacion] 
(
 @empleado_id int,
 @proyecto_id int,
 @tipo_planilla_id int,
 @dias int,
 @fechainicio date,
 @iniciamediodia bit,
 @fechafin date,
 @finmediodia bit,
 @sabadomediadia bit
 
 
)
AS
declare  @salario numeric(9,2)
--SET @empleado_id   = 8
--SET @proyecto_id  = 2
--SET @tipo_planilla_id  =1 


--salario Base
--EXEC pl.SalarioDiarioEmpleado @empleado_id,@proyecto_id ,@tipo_planilla_id ,@salario OUT
--select isnull(@salario, 0) *  ISNULL(@dias,0) 
--Percibido (Pagado Real)
--Devengado (Contratacion)
--Promedio Seis Meses
--Ultimo Sueldo
--Promedio Doce Meses


declare @bonificacion bit
declare @ingresos  bit
declare @horas_extras bit 
declare @metodo varchar(50)
declare @calculo varchar(50)

set @bonificacion = ( select    bonificacion_vacaciones   
     from cat.Proyecto where id = @proyecto_id )
set @ingresos  = ( select    ingresos_afectos_vacaciones
     from cat.Proyecto where id = @proyecto_id )
set @horas_extras =  ( select  horas_extras_vacaciones 
     from cat.Proyecto where id = @proyecto_id )
set @metodo =  ( select   metodo_vacaciones 
     from cat.Proyecto where id = @proyecto_id )
set @calculo =
( select    calculo_vacaciones
     from cat.Proyecto where id = @proyecto_id )


--set @metodo  = 'Percibido (Pagado Real)'
--set @calculo  = 'Ultimo Sueldo'
--set @calculo  = 'Promedio Seis Meses'
--set @calculo  = 'Promedio Doce Meses'


declare @mes int
if  @calculo  = 'Ultimo Sueldo'
begin
set @mes =0
end
if @calculo  = 'Promedio Seis Meses'
begin
set @mes =6
end
if @calculo  = 'Promedio Doce Meses'
begin
set @mes =12
end

declare @fechainiciopla  date
declare @fechafinpla  date

set @fechainiciopla = (select top 1 fecha_inicio  from pl.Planilla_Cabecera c
inner join pl.Planilla_Resumen r
on c.id = r.planilla_cabecera_id 
where anticipo   = 0 and isnull(vacacion,0) =0 and
empleado_id  = @empleado_id  and 
 isnull(aguinaldo ,0) =0  and isnull(bono ,0) =0
 and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id  = @proyecto_id 
order by fecha_inicio desc) 


set @fechafinpla = (select  top 1 DATEADD(month, -@mes,   fecha_inicio)   from pl.Planilla_Cabecera c
inner join pl.Planilla_Resumen r
on c.id = r.planilla_cabecera_id
where anticipo   = 0 and isnull(vacacion,0) =0 
and isnull(aguinaldo ,0) =0  and  empleado_id  = @empleado_id  and  isnull(bono ,0) =0
and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id  = @proyecto_id 
order by fecha_inicio desc) 





select  IDENTITY(int,1,1) as id, sueldo_base, sueldo_base_recibido , 
dias_base, dias_laborados, ingresos_afectos_prestaciones, monto_extras_dobles  +
monto_extras_extendidas + monto_extras_simples  as extraordinario,
bonificacion_base, bonificacion_base_recibido, 
rtrim(CONVERT(varchar(10),  fecha_inicio, 105)) as fecha,
 rtrim(CONVERT(varchar(10),fecha_fin, 105)) as fechafin     
into #temporal from pl.Planilla_Resumen r inner join pl.Planilla_Cabecera  c
on c.id = r.planilla_cabecera_id  
where empleado_id  = @empleado_id  and 
anticipo   = 0 and isnull(vacacion,0) =0 and isnull(aguinaldo ,0) =0  and isnull(bono ,0) =0
and tipo_planilla_id  = @tipo_planilla_id  and proyecto_id  = @proyecto_id 
and fecha_inicio > = @fechafinpla and fecha_inicio   < = @fechainiciopla 

declare @conte int = 0
declare @sueldobase numeric(9,2) = 0
declare @sueldobaserecibo numeric(9,2) = 0
declare @dias_base numeric(9,2) = 0
declare @dias_laborados numeric(9,2) = 0
declare @ingresosafectos numeric(9,2) = 0
declare @extraordinario numeric(9,2) = 0
declare @totalmonto numeric(9,2)
declare @bonificacion_base numeric(9,2) = 0 
declare @bonificacion_base_recibido  numeric(9,2) = 0
declare @primerplanillainicia varchar(10)
declare @ultimaplanillainicia varchar(10)
declare @primerplanillafin varchar(10)
declare @ultimaplanillafin varchar(10) 
declare @diario numeric(9,2)
declare @mensual numeric(9,2)

set @totalmonto  = 0
while (@conte < (select MAX(id) from #temporal))
begin
set @conte= @conte +1
set @extraordinario  = (select extraordinario from #temporal where ID = @conte) + @extraordinario
set @sueldobase = (select sueldo_base from #temporal where ID = @conte) + @sueldobase 
set @sueldobaserecibo  = (select sueldo_base_recibido from #temporal where ID = @conte) + @sueldobaserecibo 
set @ingresosafectos  = (select ingresos_afectos_prestaciones from #temporal where ID = @conte) + @ingresosafectos 
set @bonificacion_base  = (select bonificacion_base from #temporal where ID = @conte) + @bonificacion_base
set @bonificacion_base_recibido  = (select bonificacion_base_recibido from #temporal where ID = @conte) + @bonificacion_base_recibido
set @dias_base  = (select dias_base from #temporal where ID = @conte) + @dias_base 
set @dias_laborados  = (select dias_laborados from #temporal where ID = @conte) + @dias_laborados 
--print @sueldobaserecibo 
end
--set @dias_laborados  = (select sum(dias_laborados) from #temporal ) 
if @metodo  = 'Percibido (Pagado Real)'
begin
--print 'percibido'
set @totalmonto  = @sueldobaserecibo   + @totalmonto 
 if @bonificacion = 1
 begin
 set @totalmonto = @bonificacion_base_recibido  + @totalmonto 
 end
end

if @metodo  = 'Devengado (Contratacion)'
begin
print 'devengado'
set @totalmonto  = @sueldobase  + @totalmonto 
 if @bonificacion = 1
 begin
 set @totalmonto = @bonificacion_base  + @totalmonto 
 end
end
if @ingresos = 1 
begin
set @totalmonto  = @ingresosafectos  + @totalmonto 
end
if @horas_extras  = 1 
begin
set @totalmonto  = @extraordinario   + @totalmonto 
end
drop table #temporal
set @diario  = @totalmonto  / @dias_base 


select isnull(@diario, 0) *  ISNULL(@dias,0)


GO

alter  procedure [pl].[CalculoPagaDiaVacacion]
(
@fechainicio varchar(10),
@fechafin varchar(10),
@diaPeriodo numeric(9,2),
@checkinicio bit,
@checfin bit
)
as

---------**** Si lo desean por el dias periodo cambiar aqui
---*** setiar variable diasvar con diaperiodo
declare @diasvar numeric(9,2)
--set @diasvar =  (select DATEDIFF(day, @fechainicio , @fechafin )+ 1 )

set @diasvar =0
declare @dias int
set @dias = DATEDIFF(day, @fechainicio , @fechafin)
declare @conte int =0 
while (@conte <= @dias)
begin
  if (day(DATEADD(day,@conte ,@fechainicio))  <> 31)
  begin
    set @diasvar = @diasvar +1
  end
  set @conte  = @conte +1
end







if @checkinicio =1 
begin
set @diasvar = @diasvar -0.5
end


if @checfin  =1 
begin
set @diasvar = @diasvar -0.5
end


select @diasvar  as dia


GO
alter  procedure [pl].[AceptaVacacion]
(
@id int,
@usuario varchar(40)
)
as
begin

update  pl.Empleado_Vacacion set estado  = 'Aceptado',
updated_at  = GETDATE(), updated_by  = @usuario 
where id =@id  

declare @gozada bit
set @gozada  = (select gozada  from pl.Empleado_Vacacion  where id = @id)

if @gozada = 1
begin
		declare @tipoausencia int
		set @tipoausencia  = (select id from cat.Tipo_Ausencia  where
							abreviatura = 'VAC' and  es_vacacion =1)
 
		set @tipoausencia  = ISNULL(@tipoausencia,0)
		if @tipoausencia =0
		begin
			INSERT INTO cat.Tipo_Ausencia (abreviatura, descripcion, justificada ,
			paga , ss, es_vacacion , activo, created_at, created_by, updated_at , updated_by)
			VALUES('VAC','Vacaaciones al Personal',1,1,0,1,1,GETDATE(), '', GETDATE(), '') 
			set @tipoausencia = (select MAX(id) from cat.Tipo_Ausencia)  
		end 
	
	
	declare @tipoplanilla int
	set @tipoplanilla = (select tipo_planilla_id  from pl.Empleado_Vacacion  where id= @id) 
	DECLARE @horas_en_dia int = (select gozada  from pl.Empleado_Vacacion  where id = @id)
	    
	set @horas_en_dia = (   
    ( select horasdia from cat.FrecuenciaPago  f  inner join rh.Tipo_Planilla  t
   	  on f.id  = t.frecuencia_pago_id  where t.id = @tipoplanilla)) 
 
    DECLARE @diasdetalle int 
	set @diasdetalle =(select dias   from pl.Empleado_Vacacion  where id = @id)
	DECLARE @fecha_inicio date
	DECLARE @fecha_fin date
	
	set @fecha_inicio  = (select fecha_inicio    from pl.Empleado_Vacacion  where id = @id)
	set @fecha_fin  = (select fecha_fin  from pl.Empleado_Vacacion  where id = @id)
	
	
    set @diasdetalle =DATEDIFF(day, @fecha_inicio , @fecha_fin ) + 1


    DECLARE @horas int  
    set @horas = @diasdetalle * @horas_en_dia   
    DECLARE @proyecto_id int = (select proyecto_id   from pl.Empleado_Vacacion  where id = @id)
    DECLARE @empleado_id int = (select rh_empleado_id   from pl.Empleado_Vacacion  where id = @id)
    DECLARE @fecha date = (select fecha_inicio   from pl.Empleado_Vacacion  where id = @id)
     --DECLARE @tipo_ausencia_id int  = (select   from pl.Empleado_Vacacion  where id = @id)
      --DECLARE @usuario nvarchar(50) 
    DECLARE @fechafin date = (select DATEADD(day,dias,fecha_inicio)   from pl.Empleado_Vacacion  where id = @id)
    DECLARE @horasdetalle int = 0
 
 
     
     	
	exec	rh.IEmpleadoAusencia  @proyecto_id , @empleado_id ,@fecha ,@tipoausencia , 
           @horas , 0 ,  '' , @usuario , @fechafin ,@diasdetalle ,  @horasdetalle ,
           @horas_en_dia 
	       
  --select @tipoausencia 
end
 
end


GO

alter procedure [pl].[AceptaCalculoVacacion]
(
@id int

)
as
declare @proyectoid int  = (select proyecto_id  from Empleado_Vacacion  where id = @id)
declare @empleadoid int  = (select rh_empleado_id  from Empleado_Vacacion  where id = @id)
declare @planillaid int  = (select tipo_planilla_id   from Empleado_Vacacion  where id = @id)


update pl.Empleado_Vacacion_Resumen  set Nuevo =0 where empleado_id = @empleadoid
and proyecto_id =@proyectoid  and tipo_planilla_id  =@planillaid  and Nuevo  = 1

 declare @fecha date
 declare @fechainiico date =   (select fecha_inicio  from pl.Empleado_Vacacion  where id =@id)
 declare @fechafin date =   (select fecha_fin   from pl.Empleado_Vacacion  where id =@id)
 declare @tipo_planilla_id int  =   (select tipo_planilla_id   from pl.Empleado_Vacacion  where id =@id)
 declare @proyecto_id  int  =   (select proyecto_id   from pl.Empleado_Vacacion  where id =@id)
 declare @empleado_id  int =   (select rh_empleado_id   from pl.Empleado_Vacacion  where id =@id)
 declare @inicio_medio  bit  =   (select inicia_medio_dia    from pl.Empleado_Vacacion  where id =@id)
 declare @fin_medio  bit =   (select fin_medio_dia    from pl.Empleado_Vacacion  where id =@id)
  
 
 declare @dias int
 set @dias = DATEDIFF(day, @fechainiico, @fechafin)
 declare @conte int =0 
 delete from pl.detalleVacacion where  empleado_vacacion_id= @id
 while (@conte <= @dias)
 begin
  set @fecha =(select DATEADD(day,@conte ,@fechainiico))
  if DAY(@fecha) <> 31
  begin
  INSERT INTO pl.detalleVacacion
           (tipo_planilla_id
           ,proyecto_id,empleado_vacacion_id
           ,fecha,empleado_id)
     VALUES      
      (@tipo_planilla_id,
           @proyecto_id,@id,
           @fecha,  @empleado_id)
       
end
    set @conte = @conte +1
end



if @inicio_medio = 1
begin
update pl.detalleVacacion set medio_dia =1 where  empleado_vacacion_id= @id
and fecha = @fechainiico
end


if @fin_medio  = 1
begin
update pl.detalleVacacion set medio_dia =1 where  empleado_vacacion_id= @id
and fecha = @fechafin 
end



exec Pl.VacacionPlanilla  @id

update  pl.Empleado_Vacacion  set estado ='Aceptado'  where id = @id


GO

go
delete from  pl.Planilla_Detalle where planilla_resumen_id in  (
select id from pl.planilla_resumen where planilla_cabecera_id in  (
select id from pl.Planilla_Cabecera where vacacion =1 and DAY(fecha_fin)=15)
)
go
delete from pl.planilla_resumen where planilla_cabecera_id in  (
select id from pl.Planilla_Cabecera where vacacion =1 and DAY(fecha_fin)=15)
go
delete  from pl.Planilla_Cabecera where vacacion =1 and DAY(fecha_fin)=15


go
delete from  pl.Planilla_Detalle where planilla_resumen_id in  (
select id from pl.planilla_resumen where planilla_cabecera_id in  (
select id from pl.Planilla_Cabecera where vacacion =1 and DAY(fecha_inicio)=16)
)
go
delete from pl.planilla_resumen where planilla_cabecera_id in  (
select id from pl.Planilla_Cabecera where vacacion =1 and DAY(fecha_inicio)=16)
go
delete  from pl.Planilla_Cabecera where vacacion =1 and DAY(fecha_inicio )=16









































