# SQL store procedure and function for mortgage like repayment schedule

## Introduction:
I recently revisited and updated a small module that I originally developed over a decade ago during my tenure at a small financial institution. This module was designed to recalculate mortgage-like or fixed interest repayment schedules for loan transactions with customers. I utilized SQL Server, stored procedures, functions, and reporting services to generate reports in PDF or Excel format, integrating them into an ASP.NET C# web application on our company's intranet.

While working on the source code related to C#.NET and .RDL reports (Microsoft reporting service), I found the process straightforward. However, I also identified potential security concerns that need addressing before making these features accessible to the public.

The source code I open to public is PMT calculation logic using SQL function and It can be run very fast as this is not involved data update is simple use declared variable to enhance the report generation speed. 

Considerations for program design are as follows:
1. Users require at least six decimal places for interest calculation.
2. All displayed report results are rounded to two decimal places to maintain consistency between displayed and calculated results. To ensure consistency, I use decimal(19,2) instead of float. For instance, if over 100 lines of results are generated for calculations like Payment = Interest payment + Principal repayment, using float might result in occasional inconsistencies. Therefore, I round all further interest calculations for consistency.
3. Intermediate results, especially for daily interest calculations spanning multiple years, use decimal(19,8) to enhance accuracy.
4. I've added options for interest calculation on both a daily and monthly basis.
5. I've observed that interest rates may change over time. Calculating interest on a daily basis makes more sense, as it accommodates changes in interest rates when applying new repayment schedules while keeping remaining repayment terms and loan amounts constant.
![screen 1](https://freeware.vagweb.com/images/repay/repayment_report.png)
6. The previous version of the program relied on front-end validation to address potential bugs in the first repayment and adjustment of the last payment term [reporting service]. In my modified version, I've integrated these validations into SQL table functions.
7. The purpose of using dataCheck.xlsx is to minimize calculation errors by ensuring consistency across different programming languages or workflows. This helps to validate the accuracy of calculations. While double faults are rare, particularly in cross-checking report results from different groups, the grand total should match in most cases. I've attached an Excel formula that mirrors the SQL function shown in the screenshot. I can conduct rapid unit tests to validate that the code runs correctly and serves its intended purpose. Additionally, I can generate more test cases to ensure system stability. However, I cannot guarantee that the program is entirely bug-free, as I completed the script in just a few hours.
![screen 2](https://freeware.vagweb.com/images/repay/excel_compare.png)

## Prerequisites:
### SQL Server: MSSQL 2012 or above.
#### Software:
1. Install [SQL Server Express 2022](https://go.microsoft.com/fwlink/p/?linkid=2216019&clcid=0x409&culture=en-us&country=us) / [Developer](https://go.microsoft.com/fwlink/p/?linkid=2215158&clcid=0x409&culture=en-us&country=us) 
2. Install [SQL Server Management Studio](https://aka.ms/ssmsfullsetup)
3. Create a database with a name of your choice.
4. Download my code and testing Excel and excution scrip
```
git clone https://github.com/edwinwcw2021/Public-MSSQL-store-procedure-function.git 
```  
5. Execute the script file script_20240421.sql
6. Run the following script in SQL Server Management Studio to test it work properly or open file check_data.sql 
```
SELECT * FROM [dbo].[fnRepaySchedule] (
   1000000     -- loan 
  ,0.08        -- annual interest
  ,'2023-12-29' -- effective date
  ,'31'		   -- repayment date per month
  ,240         -- number of term (month)
  ,0		   -- interest count by monthly or daily: 0 for monthly, 1 for daily
)
GO
```  
![screen 3](https://freeware.vagweb.com/images/repay/execute_result.png)

---
 
### Use code with caution. Learn more.
Hold Ctrl and click the link (Windows/Linux).  
Hold Cmd and click the link (macOS).  

