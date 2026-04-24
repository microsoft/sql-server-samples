import sys
import numpy as np
from sklearn.pipeline import Pipeline
from datasource import DataSource
from pipeline import *
from revoscalepy.etl.RxImport import rx_import_datasource
from sklearn.metrics import classification_report



def run():

    # modify connection string to point to MLS/SQL Server instance where you restored the database
    connectionstring = 'Driver=SQL Server;Server=MLMACHINE\\SQLSERVER17;Database=velibdb;Trusted_Connection=True;'

    ds = DataSource(connectionstring)
    df = ds.loaddata()


    pipeline = Pipeline(steps= [('outliers', OutliersHandler()),
                                ('label',LabelDefiner()),
                                ('dt', DateTimeFeaturesExtractor()),
                                ('ts', TSFeaturesExtractor()),
                                ('st',  StatisticalFeaturesExtractor()),
                                ('exclusion', FeaturesExcluder()),
                                ('scaler', FeaturesScaler())]
                       )

    # Execute Pipeline

    df = pipeline.fit_transform(df)

    # split dataset

    test_size = 24 * 4 # one day test set of each station
    train = df.groupby('stationid').head(df.shape[0] - test_size)
    test = df.groupby('stationid').tail(test_size)


    # fit classifier

    clf = RxClassifier(computecontext = ds.getcomputecontext())
    coeffs = clf.fit(train)
    #print coefficients and exclude stationid Factor
    print(coeffs.tail(14))


    #  run prediction on hold out set and evaluate

    y_pred = clf.predict(test.drop(['label'], axis=1, inplace = False))
    y_truth = test['label'].as_matrix()
    print(classification_report(y_truth, y_pred))



if __name__ == "__main__":
   run()


