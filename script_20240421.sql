/****** Object:  UserDefinedFunction [dbo].[fnRepaySchedule]    Script Date: 21/04/2024 11:17:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnRepaySchedule]
(
	@loan decimal(19,2),
	@interest decimal(19,8),
	@effectiveDate date,
	@repayDate varchar(2),
	@term int,
	@interestCount int  -- 1 for daily, 0 for monthly
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
		@lastRepayDate as date;
		 
	set @rRepayDate = dbo.getFirstRepayment(@effectiveDate, @repayDate);	 
	set @settleInterest = dbo.getInterest(@effectiveDate, @rRepayDate, @loan, @interest);
	set @rterm = 1;
	
	set @repayAmount = dbo.PMT(@loan + @settleInterest, @interest/12, @term, 1);
	set @settlePrincple = @repayAmount - @settleInterest;	
	set @lastRepayDate = @rRepayDate;
	set @remindloan = @loan ;
	while(@rterm <= @term and @remindloan>0) 
		begin
			insert into @tblOutput values (@rterm, @rRepayDate, @remindloan, @repayAmount,
				@settlePrincple, @settleInterest);
			
			set @remindloan = @remindloan - @settlePrincple;
			
			set @rterm = @rterm +1;
			select @rRepayDate = dbo.getNextRepayment(@rRepayDate, @repayDate);
			if @interestCount = 1 
				set @settleInterest = dbo.getInterest(@lastRepayDate, @rRepayDate, @remindloan, @interest);
			else
				set @settleInterest = @remindloan * @interest / 12;
			if @term=@rterm
				set @repayAmount = @remindloan + @settleInterest;			
			set @settlePrincple = @repayAmount - @settleInterest;
			set @lastRepayDate = @rRepayDate;
		end
	return		
	
end
GO
/****** Object:  UserDefinedFunction [dbo].[getEndNextMonth]    Script Date: 21/04/2024 11:17:28 ******/
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
/****** Object:  UserDefinedFunction [dbo].[getFirstRepayment]    Script Date: 21/04/2024 11:17:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getFirstRepayment](@effDate Date, @repayDate varchar(2))
returns Date 
as 
begin
	declare @ret date, @intRepayDate int;
	set @intRepayDate = CAST(@repayDate as int)
	
	if(DAY(@effDate)<@intRepayDate) 
		begin 
			set @ret = EOMONTH(@effDate);
			if (day(@ret) > @intRepayDate)
				set @ret = cast(cast(YEAR(@effDate)as varchar(4))
				+'-'+ cast(month(@effDate) as varchar(2))
				+'-'+ @repayDate as date);
			else 
				if @ret = @effDate 
					set @ret=dbo.getNextRepayment(@effDate,@repayDate);
		end 
	else
		set @ret = cast(dateadd(mm, 1, cast(
		cast(YEAR(@effDate)as varchar(4))
		+'-'+ cast(month(@effDate) as varchar(2))
		+'-'+ @repayDate as date)) as date)

	return @ret;
end
GO
/****** Object:  UserDefinedFunction [dbo].[getInterest]    Script Date: 21/04/2024 11:17:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getInterest](@fmDate as date, @toDate as date, @loandAmt as decimal(19,2), @interest as decimal(19,8))
returns decimal(19,2)
as 
begin
	declare 
		@ret decimal(19,8),
		@dayPerYear int;
			
	set @dayPerYear=iif(year(@fmDate)%4=0,366,365) 

	if (year(@fmDate) <> year(@toDate))
		begin
			-- split year interest
			set @ret = @loandAmt * @interest * DATEDIFF(dd,@fmDate,cast(cast(year(@fmDate) as varchar(4)) + '1231' as date))/ @dayPerYear; 	
			set @dayPerYear=iif(year(@toDate)%4=0,366,365) 
			set @ret = @ret + @loandAmt * @interest * day(@toDate)/ @dayPerYear; 	
		end
	else
		begin
			set @ret = @loandAmt * @interest * DATEDIFF(dd,@fmDate,@toDate) / @dayPerYear; 	
		end;
	return cast(@ret as decimal(19,2));
end;
GO
/****** Object:  UserDefinedFunction [dbo].[getNextRepayment]    Script Date: 21/04/2024 11:17:28 ******/
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
/****** Object:  UserDefinedFunction [dbo].[PMT]    Script Date: 21/04/2024 11:17:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[PMT](@Princple as decimal(19,2), @interest as decimal(19,8), @rterm as float, @type as float)
returns decimal(19,6)
as 
begin
	declare @ret decimal(19,6);	
	set @ret = @Princple * @interest  * power(1 + @interest, @rterm) / ((power(1 + @interest,  @rterm) - 1) * (1 + @interest * @type));
	return @ret;
end;
GO
