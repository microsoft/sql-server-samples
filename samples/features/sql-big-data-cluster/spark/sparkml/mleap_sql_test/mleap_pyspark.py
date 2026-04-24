## train a pyspark model and export it as a mleap bundle
import os

# parse command line arguments
import argparse
parser = argparse.ArgumentParser(description = 'train pyspark model and export mleap bundle')
parser.add_argument('hdfs_path', nargs='?', default = "/spark_ml", type = str)
parser.add_argument('model_name_export', nargs='?', default = "adult_census_pipeline.zip", type = str)
args = parser.parse_args()

hdfs_path = args.hdfs_path
model_name_export = args.model_name_export

# create spark session (needed only if this file is submitted as a spark jobs)
from pyspark.sql import SparkSession

spark = SparkSession\
    .builder\
    .appName(os.path.basename(__file__))\
    .getOrCreate()

###############################################################################
## prepare data

# read the data into a spark data frame.
cwd = os.getcwd()
filename = "AdultCensusIncome.csv"

## NOTE: reading text file from local file path seems flaky!
#import urllib.request
#url = "https://amldockerdatasets.azureedge.net/" + filename
#local_filename, headers = urllib.request.urlretrieve(url, filename)
#datafile = "file://" + os.path.join(cwd, filename)

data_all = spark.read.format('csv')\
    .options(
        header='true',
        inferSchema='true',
        ignoreLeadingWhiteSpace='true',
        ignoreTrailingWhiteSpace='true')\
    .load(filename) #.load(datafile) for local file

print("Number of rows: {},  Number of coulumns : {}".format(data_all.count(), len(data_all.columns)))

#replace "-" with "_" in column names
columns_new = [col.replace("-", "_") for col in data_all.columns]
data_all = data_all.toDF(*columns_new)

data_all.printSchema()
data_all.show(5)

# choose feature columns and the label column for training.
label = "income"
#xvars = ["age", "hours_per_week"] #all numeric
xvars = ["age", "hours_per_week", "education"] #numeric + string

print("label: {}, features: {}".format(label, xvars))

select_cols = xvars
select_cols.append(label)
data = data_all.select(select_cols)

###############################################################################
## split data into train and test.

train, test = data.randomSplit([0.75, 0.25], seed=123)

print("train ({}, {})".format(train.count(), len(train.columns)))
print("test ({}, {})".format(test.count(), len(test.columns)))

train_data_path = os.path.join(hdfs_path, "AdultCensusIncomeTrain")
test_data_path = os.path.join(hdfs_path, "AdultCensusIncomeTest")

# write the train and test data sets to intermediate storage and then read
train.write.mode('overwrite').orc(train_data_path)
test.write.mode('overwrite').orc(test_data_path)

print("train and test datasets saved to {} and {}".format(train_data_path, test_data_path))

train_read = spark.read.orc(train_data_path)
test_read = spark.read.orc(test_data_path)

assert train_read.schema == train.schema and train_read.count() == train.count()
assert test_read.schema == test.schema and test_read.count() == test.count()

###############################################################################
## train model

from pyspark.ml import Pipeline, PipelineModel
from pyspark.ml.feature import OneHotEncoderEstimator, StringIndexer, IndexToString, VectorAssembler
from pyspark.ml.classification import LogisticRegression

# create a new Logistic Regression model, which by default uses "features" and "label" columns for training.
reg = 0.1
lr = LogisticRegression(regParam=reg)

# encode string columns
dtypes = dict(train.dtypes)
dtypes.pop(label)

si_xvars = []
ohe_xvars = []
featureCols = []
for idx,key in enumerate(dtypes):
    if dtypes[key] == "string":
        featureCol = "-".join([key, "encoded"])
        featureCols.append(featureCol)

        tmpCol = "-".join([key, "tmp"])
        si_xvars.append(StringIndexer(inputCol=key, outputCol=tmpCol, handleInvalid="skip")) #, handleInvalid="keep"
        ohe_xvars.append(OneHotEncoderEstimator(inputCols=[tmpCol], outputCols=[featureCol]))
    else:
        featureCols.append(key)

# string-index the label column into a column named "label"
si_label = StringIndexer(inputCol=label, outputCol='label')
#si_label._resetUid("si_label") # try to name the transformer, which seems not carried over to the fitted pipeline.

# assemble the encoded feature columns in to a column named "features"
assembler = VectorAssembler(inputCols=featureCols, outputCol="features")

# put together the pipeline
stages = []
stages.extend(si_xvars)
stages.extend(ohe_xvars)
stages.append(si_label)
stages.append(assembler)
stages.append(lr)

pipe = Pipeline(stages=stages)
print("Pipeline Created")

# train the model
model = pipe.fit(train)
print("Model Trained")
print("Model is ", model)
print("Model Stages", model.stages)

# name the string-index stage for the label so it can be identified easier later
model.stages[2]._resetUid("si_label")

###############################################################################
## evaluate model

from pyspark.ml.evaluation import BinaryClassificationEvaluator

# make prediction
pred = model.transform(test)

# evaluate. note only 2 metrics are supported out of the box by Spark ML.
bce = BinaryClassificationEvaluator(rawPredictionCol='rawPrediction')
au_roc = bce.setMetricName('areaUnderROC').evaluate(pred)
au_prc = bce.setMetricName('areaUnderPR').evaluate(pred)

print("Area under ROC: {}".format(au_roc))
print("Area Under PR: {}".format(au_prc))

###############################################################################
## save and load the model with ML persistence
# https://spark.apache.org/docs/latest/ml-pipeline.html#ml-persistence-saving-and-loading-pipelines

##NOTE: by default the model is saved to and loaded from hdfs
model_name = "AdultCensus.mml"
model_fs = os.path.join(hdfs_path, model_name)

model.write().overwrite().save(model_fs)
print("saved model to {}".format(model_fs))

# load the model file (from hdfs)
print("load pyspark model from hdfs")
model_loaded = PipelineModel.load(model_fs)
assert str(model_loaded) == str(model)

print("loaded model from {}".format(model_fs))
print("Model is " , model_loaded)
print("Model stages", model_loaded.stages)

###############################################################################
## export and import model with mleap

import mleap.pyspark
from mleap.pyspark.spark_support import SimpleSparkSerializer

# serialize the model to a local zip file in JSON format
#model_name_export = "adult_census_pipeline.zip"
model_name_path = cwd
model_file = os.path.join(model_name_path, model_name_export)

# remove an old model file, if needed.
if os.path.isfile(model_file):
    os.remove(model_file)

model_file_path = "jar:file:{}".format(model_file)
model.serializeToBundle(model_file_path, model.transform(train))

## import mleap model
model_deserialized = PipelineModel.deserializeFromBundle(model_file_path)
assert str(model_deserialized) == str(model)

print("The deserialized model is ", model_deserialized)
print("The deserialized model stages are", model_deserialized.stages)

##############################################################################
## export the final model with mleap

## remove the stringIndexer for the label column so it won't be required for prediction
model_final = model.copy()

si_label_index = -3
model_final.stages.pop(si_label_index) #si_label

## append an IndexToString transformer to the model pipeline to get the original labels
#labelReverse = IndexToString(inputCol = "label", outputCol = "predIncome") #no need to provide labels
labelReverse = IndexToString(
    inputCol = "prediction",
    outputCol = "predictedIncome",
    labels = model.stages[si_label_index].labels) #must provide labels (from si_label) otherwise will fail
model_final.stages.append(labelReverse)

pred_final = model_final.transform(test)
pred_final.printSchema()
pred_final.show(5)

# remove an old model file, if needed.
if os.path.isfile(model_file):
    os.remove(model_file)
model_final.serializeToBundle(model_file_path, model_final.transform(train))

print("persist the mleap bundle from local to hdfs")
from subprocess import Popen, PIPE
hdfs_fs_put = ["hadoop", "fs", "-put", "-f", model_file, os.path.join(hdfs_path, model_name_export)]
proc = Popen(hdfs_fs_put, stdout=PIPE, stderr=PIPE)
s_output, s_err = proc.communicate()
if (s_err):
    print("s_output: {s_output}\ns_err: {s_err}".format(s_output=s_output, s_err=s_err))

###############################################################################
