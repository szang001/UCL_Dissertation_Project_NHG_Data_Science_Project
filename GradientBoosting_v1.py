#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul  1 15:39:02 2020

@author: apple
"""
#%%
# Import all required libraries
import re
import sys
import pickle
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.impute import SimpleImputer
from sklearn.metrics import roc_curve
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import cross_val_score
from sklearn.ensemble import GradientBoostingClassifier

#deactivate warnings
import warnings
warnings.filterwarnings("ignore")

# %% [code]
# Define Functions
#define function to get diagonal and lower triangular pairs of correlation matrix
def get_redundant_pairs(df):
    pairs_to_drop = set()
    cols = df.columns
    for i in range(0, df.shape[1]):
        for j in range(0, i+1):
            pairs_to_drop.add((cols[i], cols[j]))
    return pairs_to_drop

#define function to get top absolute correlations from the previously defined matrix
def get_top_abs_correlations(df, n=5):
    au_corr = df.corr().abs().unstack()
    labels_to_drop = get_redundant_pairs(df)
    au_corr = au_corr.drop(labels=labels_to_drop).sort_values(ascending=False)
    return au_corr[0:n]

# %% [code]
# Data Preprocessing
# '/Users/apple/Desktop/Final_Files_NHH/Notting_Hill_Genssis/df_model_clean.csv'
def Data_Preprocessing(csv_path):

    data = pd.read_csv(csv_path)
    df_model = data.copy()
    model_cols = ['Tenancy Ref', 'Tenancy Type', 'Current Tenancy', 'DISABLED', 'AT RISK INDICATOR',                  
              'Gender','Ethnic Origin','Language','Marital Status',
              'Nationality', 'Relationship', 'has_garden', 'n_beds', 'had_HB', 'OAP', 
              'SUCCESSOR INDICATOR', 'Sexual Orientation', 'Tenure', 'housing_category', 'letting_type',
              'Total Months', 'Percentage In Arrears','MaxConsecMonths','LongtermArrearsNum',
              'CurrentArrearsLength', 'LAST ARREARS STATUS']
    df_model = df_model[model_cols].copy()
    df_model['disability']=0
    df_model.loc[(df_model['DISABLED']=='Y')|(df_model['AT RISK INDICATOR']=='Y'), 'disability'] = 1
    df_model.drop(['DISABLED', 'AT RISK INDICATOR'], axis=1, inplace=True)
    df_model.drop('Ethnic Origin', axis=1, inplace=True)
    df_model.fillna('ND').describe(include=['O'])
    df_model.fillna('ND', inplace=True)
    df_model.loc[(df_model['Language']!='ENGLISH')&(df_model['Language']!='ND'), 'Language'] = 'NON-ENGLISH'
    df_model.loc[(df_model['Nationality']!='BRITISH')&(df_model['Nationality']!='ND'), 'Nationality'] = 'NON-BRITISH'
    df_model.loc[df_model['Sexual Orientation']!='ND', 'Sexual Orientation'] = 'D'
    df_model.loc[(df_model['housing_category']!='GN')&(df_model['housing_category']!='ND'), 'housing_category'] = 'NON-GN'
    df_model.loc[(df_model['letting_type']!='F')&(df_model['letting_type']!='ND'), 'letting_type'] = 'NON-F'
    df_model = df_model.rename(columns = lambda x:re.sub('[^A-Za-z0-9_]+', '', x))
    df_model.set_index('TenancyRef', inplace=True)
    # df_model['LASTARREARSSTATUS'] = df_model['LASTARREARSSTATUS'].astype(str)
    objcol_headers = list(df_model.select_dtypes(include=['object']).columns)
    df_model_dummies = pd.get_dummies(data=df_model, columns=objcol_headers, drop_first=True)
    SimpleImputer(missing_values=np.nan, strategy='constant', fill_value= 0)
    X = df_model_dummies.loc[:, df_model_dummies.columns != 'LASTARREARSSTATUS']
    y = df_model_dummies.loc[:, 'LASTARREARSSTATUS']
    X_train, X_test, y_train, y_test = train_test_split( X, y, test_size=.30, random_state=1234)
    return X_train, X_test, y_train, y_test,X,y

#%%
if __name__ == '__main__':

    csv_path = sys.argv[1]
    save_path = sys.argv[2]
    model_path = sys.argv[3]
    train_or_pre = sys.argv[4]
    csv_path = r'C:\Users\Sifan.Huai\Desktop\GBoosting\Raw Modelling Table.csv'
    X_train, X_test, y_train, y_test,X,y= Data_Preprocessing(csv_path)

    if train_or_pre == 'train':
        GradientBoosting = GradientBoostingClassifier()
        GradientBoosting.fit(X_train, y_train)
        
        with open(model_path,'wb') as f:
            pickle.dump(GradientBoosting,f)
    if train_or_pre == 'prediction':
        X_test = X.values
        with open(model_path,'rb') as f:
            GradientBoosting = pickle.load(f)
        
    GradientBoosting_predictions = GradientBoosting.predict(X_test)
    GradientBoosting_probability = GradientBoosting.predict_proba(X_test)[:,1]
    if train_or_pre == 'train':
        GradientBoosting_scores = cross_val_score(GradientBoosting, X_test, y_test, cv=10, scoring='accuracy')
        fpr, tpr, thresholds = roc_curve(y_test, GradientBoosting_predictions)

    change = np.hstack((np.hstack((X_test,GradientBoosting_predictions.reshape(-1,1))),GradientBoosting_probability.reshape(-1,1)))
    columns1 = list(X.columns) + ['predictions']+['GradientBoosting_probability']
    df = pd.DataFrame(change,columns=columns1)
    # '/Users/apple/Desktop/Final_Files_NHH/Notting_Hill_Genssis/df_result.csv'
    df.to_csv(save_path,encoding='utf-8')
    # Plot ROC curve
    plt.plot([0, 1], [0, 1], 'k--')
    plt.plot(fpr, tpr)
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Curve')
    plt.savefig('ROC_curve.png')

    # Compute and print Area Under Curve: AUC score
    print("AUC: {}".format(roc_auc_score(y_test, GradientBoosting_predictions)))


'''
python GradientBoosting.py '/project/abc.csv' '/project/Result.csv' '/project/GradientBoosting.pickle' 'train'
'''
# python GradientBoosting.py '/Users/apple/Desktop/GradientBoosting.py'