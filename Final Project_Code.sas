/* Input dataset into SAS */
data sales;
infile "market_data.csv" delimiter=',' missover firstobs=2;
input sale instrspending discount tvspending stockrate price radio onlineadsspending;
run;
proc print;
run;
title 'Correlation Values';
proc corr;
var sale instrspending discount tvspending stockrate price radio onlineadsspending;
run;
title 'Descriptives for response variable';
proc means n min p25 median p75 max mean std clm stderr;
var sale;
run;
/* Analyze distribution of response variable */
title 'Histogram';
proc univariate normal;
var sale;
histogram/normal(mu=est sigma=est);
run;
title 'Scatterplots for individual x-variable';
proc gplot;
plot sale*(instrspending discount tvspending stockrate price radio onlineadsspending);
run;
title 'Scatterplot';
proc sgscatter;
matrix sale instrspending discount tvspending stockrate price radio onlineadsspending;
run;
title 'Regression Analysis';
proc reg data=sales;
model sale=instrspending discount tvspending stockrate price radio onlineadsspending/stb vif r influence;
run;
/* Writes to a new dataset to remove outliers and influential points */
data new;
set sales;
if _n_ in(93 95 276 406 413 940 962 990) then delete;
run;
proc print;
run;
/* Check for Model Assumptions */
title 'Residual Plots';
proc reg data=new;
model sale=instrspending discount tvspending stockrate price radio onlineadsspending/r influence;
plot student.*predicted.;
plot student.*(instrspending discount tvspending stockrate price radio onlineadsspending);
plot npp.*student.;
run;
/* Split data into train and test set */
proc surveyselect data=new out=xv_all seed=512216
samprate=0.75 outall;
run;
proc print;
run;
/* Using the same dataset to create new y-variable field */
data xv_all;
set xv_all;
if (selected=1) then new_y=sale;
run;
proc print;
run;
/* Run model selection on training set */
proc reg data=xv_all;
model new_y=instrspending discount tvspending stockrate price radio onlineadsspending/selection=stepwise;
run;
/* Come up with the final model */
proc reg data=xv_all;
model new_y=instrspending discount tvspending stockrate price/r influence vif;
run;
/* Get predicted value for test set */
proc reg data=xv_all;
model new_y=instrspending discount tvspending stockrate price;
output out=outm1(where=(new_y=.)) p=yhat;
run;
proc print;
run;
/* Compute performance statistics for test set */
data outm1_sum;
set outm1;
d=sale-yhat;
absd=abs(d);
run;
proc summary data=outm1_sum;
var d absd;
output out=outm1_stats std(d)=rmse mean(absd)=mae;
run;
proc print;
run;
/* Compute CV-R2 */
proc corr data=outm1;
var sale yhat;
run;
title 'Predictions';
data sale_new;
input sale instrspending discount tvspending stockrate price;
datalines;
. 500 0 900 0 0
. 400 0 700 0 0
;
proc print;
run;
title 'Using the training set to make predictions';
data pred;
set sale_new xv_all;
new_y=sale;
run;
proc print;
run;

proc reg data=pred;
model new_y=instrspending discount tvspending stockrate price/p clm cli;
run;
proc print;
run;
