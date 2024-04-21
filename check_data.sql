SELECT * FROM [dbo].[fnRepaySchedule] (
   1000000     -- loan 
  ,0.08        -- annual interest
  ,'2023-12-29' -- effective date
  ,'31'		   -- repayment date per month
  ,240         -- number of term (month)
  ,0		   -- interest count by monthly or daily: 0 for monthly, 1 for daily
)
GO

