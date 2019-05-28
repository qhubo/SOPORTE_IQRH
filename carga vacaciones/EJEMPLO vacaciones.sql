--delete from vacacion
declare @cant int =0



select pro.codigo,  pro.empleado_id, periodo, dias, identity(int,1,1) as cat
into #tem
 from dbo.vacacion va inner join rh.Empleado_Proyecto pro
 on va.codigo = pro.codigo 
 -- where  va.codigo=4


--select  empleado_id, identity(int,1,1) as cat,pagado
--into #tem from  pl.empleado_vacacion_resumen 
--where pagado >15

while (@cant <(select MAX(cat) from #tem))
begin
set @cant =@cant+1
declare @codigo varchar(20) = (select codigo from #tem where cat= @cant)
declare @DIAPENDIENTE numeric(9,2) = (select  dias from #tem where cat= @cant)
declare  @ULTIMOPERIODO int =(select periodo from #tem where cat= @cant)


--declare @empleadoid int  = (select empleado_id from #tem where cat= @cant)
--declare @pagado int = (select Pagado  from #tem where cat = @cant)
--declare @anoalata int = (select top 1 YEAR(fecha_alta)  from rh.Empleado_Proyecto where empleado_id = @empleadoid order by id desc)
--select @empleadoid as empeladoId, @pagado as pagado, @anoalata as anoalta


--declare @diap int = (select @pagado %15.00)

----select @diap

--declare @periodos int= ((@pagado-@diap)/15)

--set @anoalata = @periodos + @anoalata

--declare @CODIGO varchar(50) = (select top 1 codigo from rh.Empleado_Proyecto where empleado_id = @empleadoid order by id desc)
--declare @DIAPENDIENTE numeric(9,2) -- = 11
--declare @ULTIMOPERIODO int -- =2017
--set @DIAPENDIENTE = 15- @diap
--set @ULTIMOPERIODO = @anoalata
--select @periodos as completos
select @CODIGO as codigo, @DIAPENDIENTE, @ULTIMOPERIODO

exec pl.CargaEmpleadoVacacion @CODIGO, @DIAPENDIENTE, @ULTIMOPERIODO



end

drop table #tem




 --select * from pl.Empleado_Vacacion



--exec pl.CargaEmpleadoVacacion  4, 2.5, 2015