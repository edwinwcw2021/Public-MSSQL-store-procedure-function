USE [WF_FINANCE]
GO
/****** Object:  UserDefinedFunction [dbo].[getFirstRepayment]    Script Date: 07/22/2013 20:11:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getFirstRepayment](@effDate Date, @repayDate varchar(2))
returns Date 
as 
begin
	declare @ret date
	
	if(DAY(@effDate)<cast(@repayDate as int)) 
		begin 
			set @ret = dateadd(dd, CAST(@repayDate as int) - day(@effDate), @effDate)
			if(MONTH(@ret)=MONTH(@effDate))
				set @ret = cast(
					cast(YEAR(@effDate)as varchar(4))
					+'-'+ cast(month(@effDate) as varchar(2))
					+'-'+ @repayDate as date)
			else
				begin 
					set @ret = DATEADD(mm, 1, @effDate)
					set @ret = cast(CONVERT(varchar(8), @ret, 120) + @repayDate as DATE)
				end 
		end 
	else
		set @ret = cast(dateadd(mm, 1, cast(
		cast(YEAR(@effDate)as varchar(4))
		+'-'+ cast(month(@effDate) as varchar(2))
		+'-'+ @repayDate as date)) as date)

	return @ret;
end
GO
/****** Object:  UserDefinedFunction [dbo].[getEndNextMonth]    Script Date: 07/22/2013 20:11:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[getEndNextMonth](@curDate Date)
returns Date 
as 
begin
	declare @ret date
	set @ret = cast(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@curDate)+2,0)) as date)
	return @ret;
end
GO
/****** Object:  UserDefinedFunction [dbo].[getNextRepayment]    Script Date: 07/22/2013 20:11:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getNextRepayment](@LastRepayDate Date, @repayDate varchar(2))
returns Date 
as 
begin
	declare @ret date,
	@intRepayDate int;
	
	set @intRepayDate = CAST(@repayDate as int)
	if(@intRepayDate>28)
		begin 
			set @ret=dateadd(dd, 1, DATEADD(mm,1,@LastRepayDate))
			if(MONTH(@ret)<>month(DATEADD(mm,1,@LastRepayDate)))
				begin 
					select @ret = dbo.getEndNextMonth(@LastRepayDate)
				end 
			else
				begin 
					set @ret = DATEADD(mm, 1, @LastRepayDate)
					set @ret = cast(CONVERT(varchar(8), @ret, 120) + @repayDate as DATE)				
				end 
		end 
	else
		set @ret=DATEADD(mm,1,@LastRepayDate)

	return @ret;
end
GO
/****** Object:  UserDefinedFunction [dbo].[fnRepaySchedule2]    Script Date: 07/22/2013 20:11:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnRepaySchedule2]
(
	@loan decimal(19,2),
	@interest decimal(19,6),
	@effectiveDate date,
	@repayDate varchar(2),
	@freq int,
	@term int
)
RETURNS  @tblOutput table
(
	rterm int,
	repaydate date,
	remindloan decimal(18,2),
	repayAmount decimal(18,2),
	settlePrincple decimal(18,2),
	settleInterest decimal(18,2)		
)
as 
begin
	declare @rterm int,
		 @remindloan decimal(18,2),
		 @repayAmount decimal(18,2),
		 @settlePrincple decimal(18,2),
		 @settleInterest decimal(18,2),
		 @rRepayDate date,
		 @interFirst decimal(19,6)
		 
	
	select @rRepayDate = dbo.getFirstRepayment(@effectiveDate, @repayDate);	 
	if(cast(@repayDate as int)<=28 and DAY(@effectiveDate)=cast(@repayDate as int))
		set @interFirst = @interest / 12;
	else
		set @interFirst = @interest * DATEDIFF(dd,@effectiveDate,@rRepayDate) / 365;
	set @rterm =1;
	set @remindloan = @loan;
	set @settleInterest = @loan * @interFirst
	set @settlePrincple = 0;
	set @repayAmount = @settleInterest + @settlePrincple;
	set @interest = @interest /12;

	while(@rterm <= @term) 
		begin
			insert into @tblOutput values (@rterm, @rRepayDate, @remindloan, @repayAmount,
				@settlePrincple, @settleInterest);
			set @rterm = @rterm +1;
			set @remindloan = @remindloan - @settlePrincple;
			if @rterm % @freq=0
				begin
					set @settlePrincple = @loan / (@term/@freq);
				end
			else
				begin
					set @settlePrincple = 0
				end 			
			select @rRepayDate = dbo.getNextRepayment(@rRepayDate, @repayDate);	 
			set @settleInterest = @remindloan * @interest;
			set @repayAmount = @settleInterest + @settlePrincple;
		end
	return		
end
GO
/****** Object:  UserDefinedFunction [dbo].[fnRepaySchedule]    Script Date: 07/22/2013 20:11:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnRepaySchedule]
(
	@loan decimal(19,2),
	@interest decimal(19,6),
	@effectiveDate date,
	@repayDate varchar(2),
	@term int	
)
RETURNS @tblOutput table
(
	rterm int,
	RepayDate date,	 
	remindloan decimal(19,2),
	repayAmount decimal(19,2),
	settlePrincple decimal(19,2),
	settleInterest decimal(19,2)		
)
as 
begin
	declare @rterm int,
		@rRepayDate date,
		@remindloan decimal(19,2),
		@repayAmount decimal(19,2),
		@settlePrincple decimal(19,2),
		@settleInterest decimal(19,2),
		@interFirst decimal(19,6);
		 
	select @rRepayDate = dbo.getFirstRepayment(@effectiveDate, @repayDate);	 
	if(cast(@repayDate as int)<=28 and DAY(@effectiveDate)=cast(@repayDate as int))
		set @interFirst = @interest / 12;
	else
		set @interFirst = @interest * DATEDIFF(dd,@effectiveDate,@rRepayDate) / 365;
	
	set @interest = @interest /12;		
	set @repayAmount = @loan * @interest * power((1+@interest),@term) /
				( power((1+@interest),@term) -1);
	set @rterm =1;
	set @remindloan = @loan;
	set @settleInterest = @remindloan * @interFirst
	set @settlePrincple = @repayAmount - @settleInterest;	

	while(@rterm <= @term and @remindloan>0) 
		begin
			insert into @tblOutput values (@rterm, @rRepayDate, @remindloan, @repayAmount,
				@settlePrincple, @settleInterest);
			
			set @remindloan = @remindloan - @settlePrincple;
			
			set @rterm = @rterm +1;
			set @settleInterest = @remindloan * @interest;
			set @settlePrincple = @repayAmount - @settleInterest;
			select @rRepayDate = dbo.getNextRepayment(@rRepayDate, @repayDate);	 
			--if @rterm = @term
			--	begin
			--		set @repayAmount = @remindloan
			--		set @repayAmount = @remindloan
			--	end 
		end
	return		
end
GO
/****** Object:  StoredProcedure [dbo].[prcPreviewSchedule]    Script Date: 07/22/2013 20:11:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[prcPreviewSchedule]
(
	@loan decimal(19,2),
	@interest decimal(19,6),
	@effectiveDate date,
	@repayDate varchar(2),
	@freq int,
	@terms int,
	@repayType varchar(20)
)
as

if(@repayType<>'FIX')
	SELECT         rterm, RepayDate, remindloan, repayAmount, settlePrincple, settleInterest
	FROM             dbo.fnRepaySchedule(@loan, @interest, @effectiveDate, @repayDate, @terms)
							   AS fnRepaySchedule_1
	ORDER BY  rterm
else 
	SELECT         rterm, RepayDate, remindloan, repayAmount, settlePrincple, settleInterest
	FROM             dbo.fnRepaySchedule2(@loan, @interest, @effectiveDate, @repayDate, @freq, @terms)
							   AS fnRepaySchedule_1
	ORDER BY  rterm
GO
