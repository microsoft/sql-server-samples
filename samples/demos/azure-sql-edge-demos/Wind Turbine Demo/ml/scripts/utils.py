from azureml.core import Dataset, Model, Run
from azureml.contrib.interpret.explanation.explanation_client import ExplanationClient
from interpret.ext.blackbox import TabularExplainer

from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score, roc_auc_score, roc_curve
from sklearn.model_selection import train_test_split

import joblib
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd
import seaborn as sns
import sklearn

OUTPUT_DIR = './outputs/'

def split_dataset(dataset):
  os.makedirs(OUTPUT_DIR, exist_ok=True)

  train_data = dataset.to_pandas_dataframe()
  train_data = train_data.drop(columns=['TurbineId','Precipitation'])

  le = LabelEncoder()
  train_data['AlterBlades'] = le.fit_transform(train_data['AlterBlades'])

  for x in train_data:
      train_data[x] = pd.to_numeric(train_data[x])

  y = train_data['AlterBlades'].values.flatten()
  X = train_data.drop(['AlterBlades'], axis=1)

  X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
  return X_train, X_test, y_train, y_test

def analyze_model(clf, X_test, y_test):
  run = Run.get_context()

  preds = clf.predict(X_test)

  accuracy = accuracy_score(y_test, preds)
  run.log('Accuracy', np.float(accuracy))

  precision = precision_score(y_test, preds, average="macro")
  run.log('Precision', np.float(precision))

  recall = recall_score(y_test, preds, average="macro")
  run.log('Recall', np.float(recall))

  f1score = f1_score(y_test, preds, average="macro")
  run.log('F1 Score', np.float(f1score))

  class_names = clf.classes_
  fig, ax = plt.subplots()
  tick_marks = np.arange(len(class_names))
  plt.xticks(tick_marks, class_names)
  plt.yticks(tick_marks, class_names)
  sns.heatmap(pd.DataFrame(confusion_matrix(y_test, preds)), annot=True, cmap='YlGnBu', fmt='g')
  ax.xaxis.set_label_position('top')
  plt.tight_layout()
  plt.title('Confusion Matrix', y=1.1)
  plt.ylabel('Actual label')
  plt.xlabel('Predicted label')
  run.log_image('Confusion Matrix', plot=plt)
  plt.close()

  preds_proba = clf.predict_proba(X_test)[::,1]
  fpr, tpr, _ = roc_curve(y_test, preds_proba, pos_label = clf.classes_[1])
  auc = roc_auc_score(y_test, preds_proba)
  plt.plot(fpr, tpr, label="data 1, auc=" + str(auc))
  plt.legend(loc=4)
  run.log_image('ROC Curve', plot=plt)
  plt.close()

def save_model(clf):
  run = Run.get_context()
  dataset = run.input_datasets['training']

  # Save model in the outputs folder
  model_file_name = 'model.joblib'
  joblib.dump(value=clf, filename=os.path.join(OUTPUT_DIR, model_file_name))
  run.upload_file(model_file_name, os.path.join(OUTPUT_DIR, model_file_name))

  # Register the model
  registered_model = run.register_model(model_name='wind_turbine_model', 
                                        model_path=model_file_name,
                                        model_framework=Model.Framework.SCIKITLEARN,
                                        model_framework_version=sklearn.__version__,
                                        datasets=[(Dataset.Scenario.TRAINING, dataset)])
  return registered_model.id