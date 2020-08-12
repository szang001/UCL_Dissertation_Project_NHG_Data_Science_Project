# Notting Hill Genssis UCL Project

Pipeline for predictive models:

By using predictive model to make prediction, it could be simpfily into 3 steps:

1. Dataset preparering - by using codes form SQL Folder and Arrears_Features to pick up data from database and transform into proper formats (expect format should be like Row Modelling Table.csv from Dataset_Sample folder).

2. Change the path - open the script of final model (/Users/Desktop/Notting_Hill_Genssis/LightGBM_v1.5) on local environment (recommand spyder from Anaconda), change the path that fits your computer. 
3 paths need to be changed includes: 
  1). the path of the script, like: /Users/Downloads/project/LightGBM_v1.py
  2). the path of the dataset, like: 
                          /Users/Downloads/project/Raw_Modelling_Table.csv
  3). the path of the result that you want to save, like:                
                         /Users/Downloads/project/Result.csv
and then, change the command that you need: train/prediction

3. Outcome - copy the last line of script, and paste on your local terminal. Then, it will generate the outcomes and model.

Reminder: 

1. install lightgbm before go through the whole steps, coding is:

  pip install lightgbm
  
2. if faced any difficulties in LightGBM_V1.5, maybe try GradientBoosting_V1.2 at first to ensure script works fine on local environment.

What includes in this folder:

1. LightGBM_v1.5 - this contains prepared datasets, predicitive model (made by LightGBM, both version 1 and 1.5), script of the final model and its outcomes.

2. GradientBoosting_v1.2 - this contains predicitive model (made by GradientBoosting, version 1.2), script of model and its outcomes.

3. SQL Folder - this contains code for creating a new view in the database, which is then used as a skeleton for the final table.

4. Arrears_Features - QuantifyingArrears_MonthlyandWeekly_Final calculates arrears features for each tenancy, which are then saved as csv files. This folder also includes a notebook for creating visualisations showing trends in this data. 

5. Key_Visualisations - contains features_importance_level, ROC curve of the final model and features of users.

6. Dataset_Sample - contains proper sample of how final dataset should be look at.

7. Modelling - contains 7 algrorithm that were used and the notebook of comparasion among all.

